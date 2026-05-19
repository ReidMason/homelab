# Setup

## Configure Rustfs

We need to run Rustfs on a separate machine like a nas. This will store the fstate files.

See the compose file in [`compose/rustfs`](../compose/rustfs) for setup.

1. In the webui create a new bucket call it **terraform-state**
2. Create an access key and name it **terraform**
3. Copy the key and secret as we'll give these to terraform

## Set up Proxmox API keys

TBD...

## Talos ISO URL (`proxmox` module)

The Proxmox module downloads Talos install media. The default lives in [`modules/proxmox/variables.tf`](modules/proxmox/variables.tf) (`isos` → `url`).

To get that URL:

1. Open [factory.talos.dev](https://factory.talos.dev/).
2. Choose the **same Talos version** you run elsewhere (the path segment after the schematic ID, e.g. `v1.12.6`).
3. Select **Metal** / **amd64** and tick the `siderolabs/qemu-guest-agent` extension for the QEMU guest agent on Proxmox.
4. Copy the **Metal ISO** download link and paste it into `isos` → `url`. The link looks like  
   `https://factory.talos.dev/image/<schematic-id>/<version>/metal-amd64.iso`.  
   The schematic ID changes when you change extensions or the Talos version.

Override `isos` from an environment module block if you do not want to edit the module default.

## Init terraform

Per environment (`dev` or `prod`):

1. Copy `environments/<env>/credentials.tfvars.example` → `credentials.tfvars` and fill in Proxmox API details.
2. Copy `environments/<env>/<env>.s3.tfbackend.example` → `<env>.s3.tfbackend` with Rustfs keys.
3. Init and apply with **Just**:

```bash
just env=dev init
just env=dev apply

just env=prod init
just env=prod apply
```
