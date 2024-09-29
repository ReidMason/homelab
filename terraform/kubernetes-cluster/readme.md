When you are using talos in proxmox you have to use a specific iso with the quemu agent installed.
You also have to pass an image that talos will use to install the os

## Commands to get the config files after setup

```bash
terraform output -raw kubeconfig
terraform output -raw talosconfig
```
