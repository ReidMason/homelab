# Setup

S3-compatible remote state is provided by [Garage](https://garagehq.deuxfleurs.fr/) running on Unraid. See `compose/garage` for the setup.

## Initializing the backend

Credentials are written to `/mnt/user/appdata/garage/init/credentials` by `init.sh` after first run.

### Local development

Create `terraform/proxmox/proxmox.s3.tfbackend` (gitignored) with:

```hcl
access_key = "YOUR_ACCESS_KEY_ID"
secret_key = "YOUR_SECRET_ACCESS_KEY"
```

Then initialize:

```sh
just init
```

### Get Proxmox API key

1. Create a user by going to **datacenter** > **permissions** > **users**
2. Click \*add\*\*
3. Set the **username** to **terraform**
4. Set the **realm** to **Proxmox VE authentication**
5. Set up the password
6. Click **add**
7. Next create the API token
8. Go to `datacenter > permissons > API Tokens`
9. Click **add**
10. Set the user as the **terraform@pve** user you just created
11. Set the **token ID** to **terraform**
12. Uncheck **Privilege Separation**
13. Click **Add**
14. Note down the secret

### CI/CD

Set the following environment variables in your pipeline secrets and run `terraform init` without a backend config file — Terraform picks them up automatically:

```sh
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
TF_WORKSPACE=prod  # or dev
```

## Environments

Workspaces are used to isolate state between environments. State is stored as separate keys in the same bucket:

- `env:/dev/proxmox/terraform.tfstate`
- `env:/prod/proxmox/terraform.tfstate`

Run with `just env=prod plan` / `just env=prod apply`. Defaults to `dev` if `env` is not specified.
