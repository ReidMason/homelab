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
    nodes = {
      "be:53:5d:eb:f4:a0" = {
        ip   = "10.128.0.80"
        type = "control-plane"
      },
      "be:53:5d:eb:f4:a1" = {
        ip   = "10.128.0.81"
        type = "worker"
      },
      "be:53:5d:eb:f4:a2" = {
        ip      = "10.128.0.82"
        type    = "worker"
        enabled = false
      },
      "be:53:5d:eb:f4:a3" = {
        ip      = "10.128.0.83"
        type    = "worker"
        enabled = false
      },
      "be:53:5d:eb:f4:a4" = {
        ip      = "10.128.0.84"
        type    = "worker"
        enabled = false
      },
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}
