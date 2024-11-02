# Kubernetes Cluster

My kubernetes cluster setup using terraform. Currently this just runs using talos VMs on proxmox.

## Setup

Setup is super simple just apply the terraform config files

```bash
terraform apply
```

### Configuration files

You can access the generated configuration files using the following commands

```bash
terraform output -raw kubeconfig
terraform output -raw talosconfig
```

### Adding the kubeconfig to your local machine

This command will add the kubeconfig to your local machine so you can access the cluster using kubectl

```bash
terraform output -raw kubeconfig > ~/.kube/config
```
