terraform {
  required_version = ">= 1.14.4"

  backend "s3" {
    bucket   = "terraform-state"
    key      = "proxmox/terraform.tfstate"
    region   = "garage"

    endpoints = {
      s3 = "http://fern.lan:3900"
    }
    force_path_style            = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  } 

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.96"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
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

    node {
      name    = var.proxmox_node
      address = var.proxmox_ssh_host
    }
  }
}
