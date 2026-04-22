# Terraform

Manages Proxmox VMs via the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest) provider. Remote state is stored in a [Garage](https://garagehq.deuxfleurs.fr/) S3 bucket running on Unraid (`compose/garage`).

Run `just` recipes from `terraform/proxmox` (this directory’s justfile).

VM disks use **`import_from`** (Proxmox API disk import), not `file_id`, so **no SSH to Proxmox** is required for Terraform. The directory storage used for downloads (default **`local`**) must allow **Disk image / Import** content. `just bootstrap` enables that on `local`; on an existing node run: `pvesm set local --content iso,import,backup,vztmpl,snippets,images` once if Talos download fails with a storage error.

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

### Talos Kubernetes (optional, 1 control plane + 2 workers)

1. By default, Terraform uses `proxmox_download_file` with **`content_type = "import"`** so Proxmox downloads `metal-amd64.raw.zst` for your `talos_version` (default `1.12.6`), decompresses it, stores it under **Import** on `talos_image_datastore_id` (default `local`), and attaches disks via **`import_from`** (API only, no SSH). The API token needs download-url permissions ([bpg `proxmox_download_file` docs](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/download_file)). To use an image you uploaded yourself, set **`talos_image_id`** to its volid (e.g. `local:import/talos-metal-amd64.qcow2`). Re-run **`just bootstrap`** (or the `pvesm set local …` line above) if `local` did not yet allow **import** content.

2. Create DHCP reservations on your router so each Talos NIC MAC gets the **`ip`** you set on that node in tfvars (or omit `mac_address` / set it to `""` on a node to let Proxmox assign a MAC, then add a reservation after you read the MAC from the UI—possibly a second `apply`).

3. In `credentials.<env>.tfvars`, set `enable_talos_cluster = true`, **`talos_controlplanes`** (exactly one object: `vm_id`, `ip`, optional `mac_address`), and **`talos_workers`** (a list of the same shape, unique `vm_id`s). Scale workers by adding or removing list elements. Optionally adjust CPU, memory, or `talos_disk_gb`.

4. Apply:

   ```sh
   just env=dev apply
   ```

   The Talos provider applies machine config over the network, bootstraps etcd/Kubernetes on the control plane, joins workers, then writes kubeconfig.

5. Fetch kubeconfig:

   ```sh
   terraform workspace select dev
   terraform output -raw talos_kubeconfig > kubeconfig
   export KUBECONFIG=$PWD/kubeconfig
   kubectl get nodes
   ```

With `enable_talos_cluster = false` (default), Talos resources are omitted so existing Proxmox-only plans stay unchanged.

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

The [Terraform workflow](../.github/workflows/terraform.yml) runs only on **workflow_dispatch** (manual run). It does **not** run on pull requests.

**Why no PR runs?** A self-hosted runner sits on your LAN and the job injects real secrets (Garage, Proxmox). `terraform plan` is not safe arbitrary code: it still evaluates **data sources**, initializes the **remote state** backend, and can reach your network. Any PR branch could add malicious Terraform or providers. Fork PRs were already excluded, but **same-repo PRs** are still untrusted until you review and merge. Use **local `just plan`** or dispatch the workflow from **`main`** after merge when you want CI to touch real infrastructure.

### Repository secrets

Create these under **Settings → Secrets and variables → Actions**:

| Secret | Purpose |
|--------|---------|
| `AWS_ACCESS_KEY_ID` | Garage S3 access key (same values `setup-backend` writes into `proxmox.s3.tfbackend`) |
| `AWS_SECRET_ACCESS_KEY` | Garage S3 secret key |
| `PROXMOX_ENDPOINT` | API URL, e.g. `https://nia.lan:8006/` |
| `PROXMOX_API_TOKEN` | `terraform@pve!terraform=…` token |
| `PROXMOX_NODE` | Proxmox node name |

The S3 endpoint and bucket are in `providers.tf`; the runner must reach Garage and Proxmox on your LAN. Terraform uses `AWS_*` from the environment — you do not need `proxmox.s3.tfbackend` in CI.

### Behaviour

- **workflow_dispatch**: pick **dev** or **prod** (runner must have that label). Every run does **plan**; enable **apply** only when you intend to change infra. **Apply** runs only if the workflow was started from the **default branch** (e.g. `main`).

### Security notes

- Workflow **`permissions`** are **`contents: read`**. Checkout uses **`persist-credentials: false`**.
- Actions are pinned to **commit SHAs** (see comments in the workflow).
- Terraform uses **`TF_INPUT=false`** and **`-input=false`**.
- Optional: add a [GitHub Environment](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) with required reviewers on the apply step for production.
- Protect `.github/workflows/terraform.yml` with branch rules if multiple people can push.
