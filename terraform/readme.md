# Terraform

Manages Proxmox VMs via the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest) provider. Remote state is stored in a [Garage](https://garagehq.deuxfleurs.fr/) S3 bucket running on Unraid (`compose/garage`).

Run `just` recipes from `terraform/proxmox` (this directory’s justfile).

## Recovery (full Proxmox reset)

After a full Proxmox reset, run these commands in order:

```sh
just setup-backend                    # write proxmox.s3.tfbackend from Garage credentials
just bootstrap PROXMOX_HOST           # create user/token/permissions, write credentials.dev.tfvars
just upload-image PROXMOX_HOST        # build and upload the NixOS image from runner config
just init && just env=dev apply       # initialise Terraform and provision the VM
just register-runner TOKEN            # place runner token and start the runner service
```

Generate a runner registration token at: https://github.com/reidmason/homelab/settings/actions/runners/new

Everything is fully automatic. No prompts.

---

## First-time setup

### 1. Start Garage on Unraid

See `compose/garage` for the setup. Once Garage is running and initialized, credentials are written to `/mnt/user/appdata/garage/init/credentials` on the Unraid host.

### 2. Write the Terraform state backend config

```sh
just setup-backend
```

Reads the Garage credentials over SSH and writes `terraform/proxmox/proxmox.s3.tfbackend` (gitignored).

### 3. Bootstrap Proxmox

```sh
just bootstrap PROXMOX_HOST [env]   # env defaults to dev
```

This will:

- Copy your SSH key to the Proxmox host
- Create the `terraform@pve` user (random password — Terraform uses the API token)
- Create the `terraform` API token
- Assign the `Administrator` role at `/`
- Enable snippets and disk images on `local` storage
- Detect the node name and write `credentials.<env>.tfvars`

### 4. Build and upload the NixOS image

```sh
just upload-image PROXMOX_HOST
```

Requires `nix`. Builds the image directly from the runner config in [reidmason/dotfiles](https://github.com/reidmason/dotfiles) (`hosts/github-runner/`). The provisioned VM boots fully configured — root SSH keys come from that flake (not Terraform). Re-run `upload-image` when the NixOS version bumps, after significant config changes, or when you rotate GitHub keys (update the `fetchurl` hash in the flake first).

### 5. Apply

```sh
just init
just env=dev apply
```

### 6. Register the runner

```sh
just register-runner TOKEN
```

Generate a registration token at: https://github.com/reidmason/homelab/settings/actions/runners/new

The token only needs to be placed once — it persists across config updates and reboots.

---

## Updating the runner config

The VM’s NixOS configuration lives in [reidmason/dotfiles](https://github.com/reidmason/dotfiles) under `hosts/github-runner/`. After pushing changes to dotfiles, from `terraform/proxmox` run:

```sh
just deploy-runner             # update dev runner (default workspace)
just env=prod deploy-runner    # update prod runner
```

This resolves `runner_ip` from Terraform state, SSHs as root, and runs `nixos-rebuild switch` plus `home-manager switch` against `github:reidmason/dotfiles#github-runner-<env>` — the same pair as `system.autoUpgrade` on the runner. No image rebuild or VM recreation needed.

---

## Testing recovery

To verify the recovery flow works without touching running infrastructure, simulate exactly what a Proxmox reset destroys — the local gitignored files and the Proxmox user/token config. Remote state in Garage is intentionally left untouched, since it survives a real reset.

```sh
# 1. Simulate local machine wipe
rm terraform/proxmox/proxmox.s3.tfbackend
rm terraform/proxmox/credentials.dev.tfvars

# 2. Simulate Proxmox reset (wipes user and token config)
ssh root@nia.lan 'pveum user token remove terraform@pve terraform; pveum user delete terraform@pve'

# 3. Run the recovery
just setup-backend
just bootstrap nia.lan
just init
just env=dev plan
```

A clean `plan` with **no changes** confirms that Terraform reconnected to the existing remote state and the live infrastructure matches — recovery is working correctly.

---

## Environments

Workspaces isolate state between environments, stored as separate keys in the same bucket:

- `env:/dev/proxmox/terraform.tfstate`
- `env:/prod/proxmox/terraform.tfstate`

Run with `just env=prod plan` / `just env=prod apply`. Defaults to `dev`.

## CI/CD

Set these secrets in your pipeline and run `terraform init` without a backend config file — Terraform picks them up automatically:

```sh
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
TF_WORKSPACE=prod
```
