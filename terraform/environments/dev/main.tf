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
  }
}

module "proxmox" {
  source               = "../../modules/proxmox"
  node_name            = var.proxmox_node
  iso_datastore_id     = "local"
  vm_disk_datastore_id = "local-lvm"
  kubernetes_cluster = {
    enabled                 = true
    control_planes          = 1
    control_plane_cores     = 2
    control_plane_memory_mb = 4096
    control_plane_disk_gb   = 50
    workers                 = 1
    worker_cores            = 2
    worker_memory_mb        = 4096
    worker_disk_gb          = 50
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}
