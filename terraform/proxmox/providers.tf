terraform {
  required_version = ">= 1.14.4"

  backend "s3" {
    bucket   = "terraform-state"
    key      = "proxmox/terraform.tfstate"
    region   = "us-east-1"

    endpoint                    = "http://192.168.1.x:9000"
    force_path_style            = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  } 

  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  ssh {
    agent    = true
    username = var.proxmox_ssh_username
  }
}
