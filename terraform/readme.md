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

### Create the terraform user

1. Create a user by going to **datacenter** > **permissions** > **users**
2. Click \*add\*\*
3. Set the **username** to **terraform**
4. Set the **realm** to **Proxmox VE authentication**
5. Set up the password
6. Click **add**

### Get Proxmox API key

1. Next create the API token
2. Go to `datacenter > permissons > API Tokens`
3. Click **add**
4. Set the user as the **terraform@pve** user you just created
5. Set the **token ID** to **terraform**
6. Uncheck **Privilege Separation**
7. Click **Add**
8. Note down the secret

### Add permissons

1. Click on the **permissions** tab
2. Click the **add** dropdown and select **User Permission**
3. Set the path to `/` and user to your terraform user
4. For roles select `Administrator`
   1. You can be more specific with roles but who has time for that
5. Click **add**

### Generate the cloud-init image

1. On a linux host clone this repo
2. Run the just command using the proxmox host as your target `just upload-image PROXMOX_HOST`

### Copy SSH key to proxmox

`ssh-copy-id root@PROXMOX_HOST`

### Enable snippets

1.

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
