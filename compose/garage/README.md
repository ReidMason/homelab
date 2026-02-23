# Setup

1. Run `create-garage-toml.sh` and copy the generated `garage.toml` and `init.sh` to `/mnt/user/appdata/garage/garage.toml`.
2. Run `docker compose up -d` on the host. The `garage-init` service will automatically configure the layout, create the `terraform-state` bucket, and create an access key.
3. Run the `init.sh` script
4. Retrieve the credentials from `/mnt/user/appdata/garage/init/credentials` on the host and use them to configure your Terraform S3 backend.
