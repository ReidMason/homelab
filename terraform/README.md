# Setup

## Configure Rustfs

We need to run Rustfs on a separate machine like a nas. This will store the fstate files.

See the compose file in `bootstrap/rustfs` for setup.

1. In the webui create a new bucket call it **terraform-state**
2. Create an access key and name it **terraform**
3. Copy the key and secret as we'll give these to terraform

## Set up Proxmox API keys

TBD...

## Init terraform

In the environment directory e.g. `environments/dev` run the terraform init command

1. Put the rustfs key and secret into the `ENV.secrets.tfbackend` file
2. Init terraform with **Just**

```bash
just init
```
