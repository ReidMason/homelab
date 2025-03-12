module "kube_servers" {
  source = "../modules/kube-servers"

  target_node = "nia"

  kube_servers = {
    "160" = {
      name    = "nia-kube-controlplane-1"
      desc    = "Kubernetes controlplane 1"
      macaddr = "D4:B8:23:EF:D6:F6"
      ip      = "10.128.0.65"
      cores   = 2
      memory  = 4096
      storage = "local-lvm"
      type    = "controlplane"
    },
    "161" = {
      name    = "nia-kube-worker-1"
      desc    = "Kubernetes worker 1"
      macaddr = "6A:64:FF:EA:0D:C5"
      ip      = "10.128.0.66"
      cores   = 2
      memory  = 4096
      storage = "local-lvm"
      type    = "worker"
    }
  }

  proxmox_api_url          = var.proxmox_api_url
  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
}
