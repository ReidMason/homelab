locals {
  kube_servers = {
    "160" = {
      name = "ivy-kube-controlplane-1"
      ip   = "10.128.0.60"
      type = "controlplane"
    },
    "161" = {
      name = "ivy-kube-worker-1"
      ip   = "10.128.0.61"
      type = "worker"
    },
    "162" = {
      name = "ivy-kube-worker-2"
      ip   = "10.128.0.62"
      type = "worker"
    }
    "163" = {
      name = "nia-kube-controlplane-1"
      ip   = "10.128.0.65"
      type = "controlplane"
    },
    "164" = {
      name = "nia-kube-worker-1"
      ip   = "10.128.0.66"
      type = "worker"
    }
  }
}

module "talos-setup" {
  source = "../modules/talos"

  kube_servers = local.kube_servers
}
