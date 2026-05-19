terraform {
  backend "s3" {
    bucket = "terraform-state"

    key    = "terraform.prod.tfstate"
    region = "fern"

    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true

    endpoint = "http://fern.lan:9000"
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.96"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0-beta.2"
    }
  }
}

locals {
  talos_version      = "1.12.6"
  kubernetes_version = "1.35.3"
  talos_nodes = {
    "20" = { type = "control-plane", hostname = "kube1.prod.internal", mac_address = "bc:24:11:00:00:20" }
    "21" = { type = "worker", hostname = "kube2.prod.internal", mac_address = "bc:24:11:00:00:21" }
  }
}

module "talos" {
  source = "../../modules/talos"
  cluster_config = {
    cluster_name = "kubernetes-prod"
    nodes        = local.talos_nodes
  }
  talos_version      = local.talos_version
  kubernetes_version = local.kubernetes_version
  nameservers        = ["10.128.20.1", "1.1.1.1"]
  depends_on         = [module.proxmox]
}

module "proxmox" {
  source               = "../../modules/proxmox"
  node_name            = var.proxmox_node
  iso_datastore_id     = "local"
  vm_disk_datastore_id = "nvme-storage"
  talos_version        = local.talos_version

  control_plane_defaults = {
    cores     = 2
    memory_mb = 8192
    disk_gb   = 50
  }

  worker_defaults = {
    cores     = 2
    memory_mb = 8192
    disk_gb   = 50
  }

  kubernetes_cluster = {
    enabled = true
    nodes   = local.talos_nodes
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}

output "talosconfig" {
  description = "Talos client configuration (same CAs as Terraform)."
  value       = module.talos.talosconfig
  sensitive   = true
}

output "kubeconfig" {
  description = "Cluster admin kubeconfig."
  value       = module.talos.kubeconfig
  sensitive   = true
}
