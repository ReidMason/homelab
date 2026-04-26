variable "node_type" {
  type        = string
  description = "The type of node to create"
  validation {
    condition     = contains(["control-plane", "worker"], var.node_type)
    error_message = "Invalid node type. Must be one of: control-plane, worker."
  }
}

variable "vm_id" {
  type        = number
  description = "Proxmox VM ID; use 100 + last IPv4 octet for Talos nodes (.20-.59 → 120-159)"
  validation {
    condition     = var.vm_id >= 120 && var.vm_id < 160
    error_message = "VM ID must be between 120 and 159 (100 + node last octet for .20-.59)."
  }
}

variable "proxmox_node_name" {
  type        = string
  description = "The name of the proxmox node to create the VM on"
  validation {
    condition     = length(var.proxmox_node_name) > 0
    error_message = "Proxmox node name must be a non-empty string."
  }
}

variable "vm_disk_datastore_id" {
  type        = string
  description = "The datastore ID of the VM disk"
  validation {
    condition     = length(var.vm_disk_datastore_id) > 0
    error_message = "VM disk datastore ID must be a non-empty string."
  }
}

variable "cores" {
  type        = number
  description = "The number of cores to allocate to the VM"
  validation {
    condition     = var.cores > 0
    error_message = "Cores must be greater than 0."
  }
}

variable "memory_mb" {
  type        = number
  description = "The amount of memory to allocate to the VM"
  validation {
    condition     = var.memory_mb > 0
    error_message = "Memory must be greater than 0."
  }
}

variable "disk_size_gb" {
  type        = number
  description = "The size of the disk to allocate to the VM"
  validation {
    condition     = var.disk_size_gb > 0
    error_message = "Disk size must be greater than 0."
  }
}

variable "iso_file_id" {
  type        = string
  description = "The ID of the ISO file to use for the VM"
  validation {
    condition     = length(var.iso_file_id) > 0
    error_message = "ISO file ID must be a non-empty string."
  }
}

variable "mac_address" {
  type        = string
  description = "Stable NIC MAC for DHCP reservations (e.g. bc:24:11:aa:00:01)"
  validation {
    condition     = can(regex("^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$", var.mac_address))
    error_message = "mac_address must be six colon-separated hex octets (e.g. bc:24:11:aa:00:01)."
  }
}

