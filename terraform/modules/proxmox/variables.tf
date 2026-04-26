variable "node_name" {
  type = string
}

variable "iso_datastore_id" {
  type = string
}

variable "vm_disk_datastore_id" {
  type = string
}

variable "talos_schematic_id" {
  type        = string
  default     = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
  description = "The schematic ID of the Talos image to use"
}

variable "talos_version" {
  type        = string
  description = "The version of the Talos image to use"
}

variable "talos_arch" {
  type        = string
  default     = "amd64"
  description = "The architecture of the Talos image to use"
}

variable "isos" {
  type = map(object({
    url = string
  }))
  default = {}
}

variable "kubernetes_cluster" {
  type = object({
    enabled = optional(bool, false)
    nodes = map(object({
      type        = string
      hostname    = string
      mac_address = string
      enabled     = optional(bool, true)
      cores       = optional(number, null)
      memory_mb   = optional(number, null)
      disk_gb     = optional(number, null)
    }))
  })
  validation {
    condition = alltrue([
      for _, node in var.kubernetes_cluster.nodes :
      contains(["control-plane", "worker"], node.type)
    ])
    error_message = "Each node must have a type of either control-plane or worker."
  }
  validation {
    condition = alltrue([
      for k in keys(var.kubernetes_cluster.nodes) :
      can(tonumber(k)) && tonumber(k) == floor(tonumber(k)) && tonumber(k) >= 20 && tonumber(k) < 60
    ])
    error_message = "Each nodes map key must be the last IPv4 octet as a decimal string in 20–59 (Proxmox vm_id = 100 + that number)."
  }
  validation {
    condition = length(distinct([
      for _, node in var.kubernetes_cluster.nodes : lower(node.mac_address)
    ])) == length(var.kubernetes_cluster.nodes)
    error_message = "Each node must have a unique mac_address."
  }
  validation {
    condition = alltrue([
      for _, node in var.kubernetes_cluster.nodes : length(trimspace(node.hostname)) > 0
    ])
    error_message = "Each node must have a non-empty hostname."
  }
  validation {
    condition = length(distinct([
      for _, node in var.kubernetes_cluster.nodes : lower(trimspace(node.hostname))
    ])) == length(var.kubernetes_cluster.nodes)
    error_message = "Each node must have a unique hostname."
  }
}

variable "control_plane_defaults" {
  type = object({
    cores     = optional(number, 2)
    memory_mb = optional(number, 4096)
    disk_gb   = optional(number, 50)
  })
}

variable "worker_defaults" {
  type = object({
    cores     = optional(number, 2)
    memory_mb = optional(number, 4096)
    disk_gb   = optional(number, 50)
  })
}
