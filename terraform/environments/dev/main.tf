terraform {
  backend "s3" {
    bucket = "terraform-state"

    key    = "terraform.dev.tfstate"
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
  talos_schematic_id = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
  talos_version      = "1.12.6"
  talos_arch         = "amd64"
  kubernetes_version = "1.35.3"
  nodes = {
    "181" = {
      mac_address = "be:53:5d:eb:f4:a0"
      ip          = "10.128.0.80"
      type        = "control-plane"
    }
    "182" = {
      mac_address = "be:53:5d:eb:f4:a1"
      ip          = "10.128.0.81"
      type        = "worker"
    }
    "183" = {
      mac_address = "be:53:5d:eb:f4:a2"
      ip          = "10.128.0.82"
      type        = "worker"
      enabled     = false
    }
    "184" = {
      mac_address = "be:53:5d:eb:f4:a3"
      ip          = "10.128.0.83"
      type        = "worker"
      enabled     = false
    }
    "185" = {
      mac_address = "be:53:5d:eb:f4:a4"
      ip          = "10.128.0.84"
      type        = "worker"
      enabled     = false
    }
  }
}

module "talos" {
  source = "../../modules/talos"
  cluster_config = {
    cluster_name = "kubernetes-dev"
    nodes        = local.nodes
  }
  talos_schematic_id = local.talos_schematic_id
  talos_version      = local.talos_version
  talos_arch         = local.talos_arch
  kubernetes_version = local.kubernetes_version
  depends_on         = [module.proxmox]
}

module "proxmox" {
  source               = "../../modules/proxmox"
  node_name            = var.proxmox_node
  iso_datastore_id     = "local"
  vm_disk_datastore_id = "local-lvm"
  talos_schematic_id   = local.talos_schematic_id
  talos_version        = local.talos_version
  talos_arch           = local.talos_arch

  control_plane_defaults = {
    cores     = 2
    memory_mb = 4096
    disk_gb   = 50
  }

  worker_defaults = {
    cores     = 2
    memory_mb = 4096
    disk_gb   = 50
  }

  kubernetes_cluster = {
    enabled = true
    nodes   = local.nodes
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
