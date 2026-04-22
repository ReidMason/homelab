# Terraform

Manages Proxmox VMs via the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest) provider. Remote state is stored in a [Garage](https://garagehq.deuxfleurs.fr/) S3 bucket running on Unraid (`compose/garage`).

Run `just` recipes from `terraform/proxmox` (this directory’s justfile).

The optional **GitHub runner** VM is off by default (`enable_github_runner = false`). When enabled, it uses **`import_from`** with **`local:999/nixos-cloud.qcow2`** (run **`just upload-image`** first). **Talos** matches the old **`kubernetes-cluster-v2` / `proxmox-vms`** setup: an **empty virtio disk** plus **`metal-amd64.iso`** on **IDE2** (same idea as `local:iso/talos-nocloud-amd64.iso` there). By default **`proxmox_download_file`** pulls **`metal-amd64.iso`** onto **`local`** (no zstd, no SSH). Set **`talos_image_id`** to a volid such as **`local:iso/talos-metal-amd64.iso`** if you upload the ISO yourself.

## Recovery (full Proxmox reset)

After a full Proxmox reset, run these commands in order:

```sh
just setup-backend                    # write proxmox.s3.tfbackend from Garage credentials
just bootstrap PROXMOX_HOST           # create user/token/permissions, write credentials.dev.tfvars
just init && just env=dev apply       # initialise Terraform and apply (Talos / other VMs per tfvars)
# If enable_github_runner = true in credentials.<env>.tfvars:
#   just upload-image PROXMOX_HOST && just env=dev apply
#   just register-runner TOKEN      # https://github.com/reidmason/homelab/settings/actions/runners/new
```

With the runner disabled (default), skip `upload-image` / `register-runner` unless you turn **`enable_github_runner`** on.

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
- Enable ISO, **Import**, snippets, disk images, etc. on `local` storage (ISO for Talos URL download; **images** for `local:999/…` when you use the runner)
- Detect the node name and write `credentials.<env>.tfvars`

### 4. GitHub runner only: NixOS image + VM

Set **`enable_github_runner = true`** in `credentials.<env>.tfvars`, then:

```sh
just upload-image PROXMOX_HOST
```

Requires `nix`. Uploads **`local:999/nixos-cloud.qcow2`**. Re-run when the runner flake changes materially or you rotate keys (update the `fetchurl` hash in dotfiles if needed).

### 5. Apply

```sh
just init
just env=dev apply
```

### Talos Kubernetes (optional, 1 control plane + 2 workers)

1. **Default (`talos_image_id` empty):** `proxmox_download_file` pulls **`metal-amd64.iso`** from GitHub onto **`talos_image_datastore_id`** (usually **`local`**). Each Talos VM uses **OVMF** (`bios = "ovmf"`, **`efi_disk`**, **`machine = "q35"`**) because the Talos ISO is **UEFI-only**; with SeaBIOS you typically see **“no bootable device”**. The ISO is on **IDE2** with **`boot_order`** preferring it over the empty **`virtio0`** disk. There is **no Proxmox `initialization` / cloud-init** on these VMs (it would grab **IDE2** and replace the boot CD). **`install.image`** in the config patch points at **`ghcr.io/siderolabs/installer`** with the same release tag as **`talos_version`**. **Optional:** set **`talos_image_id = "local:iso/your-talos.iso"`** to skip the download.

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

**Apply mode:** `talos_machine_configuration_apply` uses **`apply_mode = "staged"`** so config is written and picked up after reboot. That avoids **`staged_if_needing_reboot`**, which has triggered **inconsistent final plan** errors in the Talos provider when `resolved_apply_mode` changes between plan and apply. If nodes were left half-updated after a failed apply, run **`terraform apply`** again after fixing other errors; reboot stuck VMs from Proxmox if they stay in maintenance with staged config pending.

### 6. Register the runner

Only if **`enable_github_runner = true`**. Generate a token at https://github.com/reidmason/homelab/settings/actions/runners/new then:

```sh
just register-runner TOKEN
```

The token only needs to be placed once — it persists across config updates and reboots.

---

## Updating the runner config

When the runner is enabled, the VM’s NixOS configuration lives in [reidmason/dotfiles](https://github.com/reidmason/dotfiles) under `hosts/github-runner/`. After pushing changes to dotfiles, from `terraform/proxmox` run:

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
