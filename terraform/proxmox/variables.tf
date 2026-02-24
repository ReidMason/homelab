# Proxmox connection
variable "proxmox_endpoint" {
  description = "URL of the Proxmox API, e.g. https://192.168.1.10:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the format user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification (use if Proxmox has a self-signed cert)"
  type        = bool
  default     = true
}

variable "proxmox_ssh_username" {
  description = "SSH username for Proxmox host"
  type        = string
  default     = "root"
}

variable "proxmox_node" {
  description = "Proxmox node name to create resources on"
  type        = string
}

variable "proxmox_datastore" {
  description = "Proxmox datastore for VM disks (e.g. local-lvm)"
  type        = string
  default     = "local-lvm"
}

# VM
variable "runner_vm_id" {
  description = "VM ID in Proxmox (must be unique)"
  type        = number
  default     = 200
}

variable "nixos_image_id" {
  description = "Proxmox file ID of the pre-uploaded NixOS cloud image (run 'just upload-image' first)"
  type        = string
  default     = "local:iso/nixos-cloud.qcow2"
}

variable "github_username" {
  description = "GitHub username — SSH public keys fetched from github.com/username.keys"
  type        = string
}
