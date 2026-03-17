#!/usr/bin/env bash
# Bootstraps a Proxmox host for use with Terraform and writes credentials.<env>.tfvars.
# Safe to re-run — skips steps that are already complete.
#
# Usage: ./bootstrap-proxmox.sh <proxmox-host> [env]
#   e.g. ./bootstrap-proxmox.sh nia.lan dev
set -euo pipefail

PROXMOX_HOST="${1:?Usage: bootstrap-proxmox.sh <proxmox-host> [env] [github-username]}"
ENV="${2:-dev}"
GITHUB_USERNAME="${3:-}"
SSH="ssh -o StrictHostKeyChecking=accept-new root@${PROXMOX_HOST}"
SCRIPT_DIR="${BASH_SOURCE%/*}"
CREDS_FILE="${SCRIPT_DIR}/credentials.${ENV}.tfvars"

# ── 1. SSH key ────────────────────────────────────────────────────────────────

echo "→ Copying SSH key to Proxmox host (you may be prompted for the root password)..."
ssh-copy-id -o StrictHostKeyChecking=accept-new "root@${PROXMOX_HOST}"

# ── 2. Terraform user ─────────────────────────────────────────────────────────

echo "→ Creating terraform@pve user..."
if $SSH "pveum user list --output-format json" | grep -q '"terraform@pve"'; then
  echo "  Already exists, skipping."
else
  TF_PASSWORD=$(openssl rand -base64 32)
  $SSH "pveum user add terraform@pve --password '${TF_PASSWORD}'"
  echo "  Done. (password randomly generated — Terraform uses the API token, not this password)"
fi

# ── 3. API token ──────────────────────────────────────────────────────────────

echo "→ Creating terraform API token..."
if $SSH "pveum user token list terraform@pve --output-format json" | grep -q '"terraform"'; then
  echo "  Token already exists."
  echo "  ⚠  The secret can only be read at creation time. To regenerate:"
  echo "       ssh root@${PROXMOX_HOST} 'pveum user token remove terraform@pve terraform'"
  echo "     Then re-run this script."
  TOKEN_SECRET=""
else
  TOKEN_JSON=$($SSH "pveum user token add terraform@pve terraform --privsep 0 --output-format json")
  TOKEN_SECRET=$(echo "$TOKEN_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['value'])")
  echo "  Done."
fi

# ── 4. Permissions ────────────────────────────────────────────────────────────

echo "→ Assigning Administrator role to terraform@pve on /..."
$SSH "pveum acl modify / --users terraform@pve --roles Administrator"
echo "  Done."

# ── 5. Local storage content types ───────────────────────────────────────────

echo "→ Enabling snippets and disk images on local storage..."
$SSH "pvesm set local --content iso,backup,vztmpl,snippets,images"
echo "  Done."

# ── 6. Detect node name ───────────────────────────────────────────────────────

echo "→ Detecting Proxmox node name..."
NODE_NAME=$($SSH "pvesh get /nodes --output-format json" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['node'])")
echo "  Node: ${NODE_NAME}"

# ── 7. Write credentials file ────────────────────────────────────────────────

if [ -n "${TOKEN_SECRET:-}" ]; then
  echo "→ Writing ${CREDS_FILE}..."

  if [ ! -f "$CREDS_FILE" ]; then
    if [ -z "$GITHUB_USERNAME" ]; then
      read -rp "  GitHub username (for SSH key fetching): " GITHUB_USERNAME
    fi
    cat > "$CREDS_FILE" <<EOF
proxmox_endpoint     = "https://${PROXMOX_HOST}:8006/"
proxmox_api_token    = "terraform@pve!terraform=${TOKEN_SECRET}"
proxmox_ssh_username = "root"
proxmox_node         = "${NODE_NAME}"
proxmox_ssh_host     = "${PROXMOX_HOST}"

github_username = "${GITHUB_USERNAME}"
EOF
    echo "  Done. Created ${CREDS_FILE}"
  else
    # File already exists — only update the token line
    sed -i '' "s|proxmox_api_token.*|proxmox_api_token    = \"terraform@pve!terraform=${TOKEN_SECRET}\"|" "$CREDS_FILE"
    echo "  Updated proxmox_api_token in existing ${CREDS_FILE}"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Bootstrap complete. Next steps:"
echo ""
echo "  just upload-image ${PROXMOX_HOST}"
echo "  just init"
echo "  just env=${ENV} apply"
