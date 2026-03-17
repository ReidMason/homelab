#!/bin/sh
set -e

GARAGE="docker exec garage-garage-1 /garage"
INIT_DONE="/mnt/user/appdata/garage/init/done"
CREDS_FILE="/mnt/user/appdata/garage/init/credentials"

# Skip if already run successfully
if [ -f "$INIT_DONE" ]; then
    echo "Garage already initialized, skipping."
    exit 0
fi

echo "Starting Garage initialization..."

# Get the node ID from the status output (first hex column, strip trailing ellipsis)
NODE_ID=$($GARAGE status | awk '/^[[:xdigit:]]/{gsub(/…/, ""); print $1; exit}')
echo "Node ID: $NODE_ID"

# Assign the node a zone and storage capacity, then apply the layout.
# Adjust -c to reflect the actual storage capacity available in your data_dir.
$GARAGE layout assign -z dc1 -c 100G "$NODE_ID"
LAYOUT_VERSION=$($GARAGE layout show | awk '/Current cluster layout version:/{print $NF}')
$GARAGE layout apply --version $((LAYOUT_VERSION + 1))
echo "Layout applied."

# Create the bucket used for Terraform remote state
BUCKET="terraform-state"
$GARAGE bucket create "$BUCKET"
echo "Bucket '$BUCKET' created."

# Create an access key and capture the credentials from the output
KEY_OUTPUT=$($GARAGE key create terraform-key)
ACCESS_KEY=$(echo "$KEY_OUTPUT" | awk '/^Key ID:/{print $NF}')
SECRET_KEY=$(echo "$KEY_OUTPUT" | awk '/^Secret key:/{print $NF}')

# Grant read/write access on the bucket to the new key
$GARAGE bucket allow --read --write "$BUCKET" --key terraform-key
echo "Key 'terraform-key' authorized on bucket '$BUCKET'."

# Write credentials to a file on the shared init volume so they can be
# retrieved from the host at /mnt/user/appdata/garage/init/credentials
cat > "$CREDS_FILE" << EOF
ACCESS_KEY_ID=$ACCESS_KEY
SECRET_ACCESS_KEY=$SECRET_KEY
ENDPOINT=http://<your-garage-host>:3900
REGION=garage
BUCKET=$BUCKET
EOF

touch "$INIT_DONE"
echo "Initialization complete. Credentials saved to $CREDS_FILE"
