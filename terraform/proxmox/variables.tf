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
  description = "SSH username for Proxmox host (used for operations the API cannot perform)"
  type        = string
  default     = "root"
}

variable "proxmox_node" {
  description = "Proxmox node name to create resources on"
  type        = string
}

# VM settings
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "terraform-vm"
}

variable "vm_id" {
  description = "VM ID (must be unique in the cluster)"
  type        = number
  default     = 100
}

variable "vm_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "vm_memory_mb" {
  description = "Memory in megabytes"
  type        = number
  default     = 2048
}

variable "vm_disk_size" {
  description = "Disk size (e.g. 20G)"
  type        = string
  default     = "20G"
}

variable "vm_datastore" {
  description = "Proxmox datastore to place the disk on (e.g. local-lvm)"
  type        = string
  default     = "local-lvm"
}

variable "vm_iso" {
  description = "ISO image to boot from, in datastore:iso/filename format (e.g. local:iso/ubuntu-24.04.iso)"
  type        = string
  default     = null
}

variable "vm_tags" {
  description = "List of tags to apply to the VM"
  type        = list(string)
  default     = ["terraform"]
}
