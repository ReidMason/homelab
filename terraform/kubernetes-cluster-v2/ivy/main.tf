locals {
  kube_servers = {
    "160" = {
      name    = "ivy-kube-controlplane-1"
      desc    = "Kubernetes controlplane 1"
      macaddr = "6e:c8:77:4f:70:1a"
      ip      = "10.128.0.60"
      cores   = 4
      memory  = 4096
      storage = "nvme-storage"
      type    = "controlplane"
    },
    "161" = {
      name    = "kube-worker-1"
      desc    = "Kubernetes worker 1"
      macaddr = "82:39:c3:cf:7b:d9"
      ip      = "10.128.0.61"
      cores   = 4
      memory  = 4096
      storage = "nvme-storage"
      type    = "worker"
    }
    "162" = {
      name    = "kube-worker-2"
      desc    = "Kubernetes worker 2"
      macaddr = "82:5b:dc:cb:e6:34"
      ip      = "10.128.0.62"
      cores   = 4
      memory  = 4096
      storage = "nvme-storage"
      type    = "worker"
    }
  }
}

module "kube_servers" {
  source = "../modules/proxmox-vms"

  target_node  = "ivy"
  kube_servers = local.kube_servers

  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}
