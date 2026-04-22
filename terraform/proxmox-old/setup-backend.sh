#!/usr/bin/env bash
# Reads Garage S3 credentials from Unraid and writes proxmox.s3.tfbackend.
# Safe to re-run — overwrites the backend file with fresh values.
#
# Usage: ./setup-backend.sh <unraid-host>
#   e.g. ./setup-backend.sh fern.lan
set -euo pipefail

UNRAID_HOST="${1:?Usage: setup-backend.sh <unraid-host>}"
CREDS_FILE="/mnt/user/appdata/garage/init/credentials"
OUTPUT="${BASH_SOURCE%/*}/proxmox.s3.tfbackend"

echo "→ Reading Garage credentials from ${UNRAID_HOST}:${CREDS_FILE}..."

CREDS=$(ssh -o StrictHostKeyChecking=accept-new "root@${UNRAID_HOST}" "cat ${CREDS_FILE}" 2>/dev/null) || {
  echo "  ✗ Could not read credentials file. Is Garage initialized?"
  echo "    Expected: ${UNRAID_HOST}:${CREDS_FILE}"
  exit 1
}

ACCESS_KEY=$(echo "$CREDS" | awk -F= '/^ACCESS_KEY_ID/{print $2}')
SECRET_KEY=$(echo "$CREDS" | awk -F= '/^SECRET_ACCESS_KEY/{print $2}')

if [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ]; then
  echo "  ✗ Credentials file is missing ACCESS_KEY_ID or SECRET_ACCESS_KEY."
  exit 1
fi

cat > "$OUTPUT" <<EOF
access_key = "${ACCESS_KEY}"
secret_key = "${SECRET_KEY}"
EOF

echo "  Done. Written to ${OUTPUT}"
