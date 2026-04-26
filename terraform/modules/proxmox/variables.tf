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
  description = "The schematic ID of the Talos image to use"
}

variable "talos_version" {
  type        = string
  description = "The version of the Talos image to use"
}

variable "talos_arch" {
  type        = string
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
      type      = string
      enabled   = optional(bool, true)
      cores     = optional(number, null)
      memory_mb = optional(number, null)
      disk_gb   = optional(number, null)
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
      length(split(".", k)) == 4 &&
      can(tonumber(element(split(".", k), 3))) &&
      tonumber(element(split(".", k), 3)) >= 20 &&
      tonumber(element(split(".", k), 3)) < 60
    ])
    error_message = "Each nodes map key must be an IPv4 address with last octet in 20-59 (Proxmox vm_id = 100 + that octet)."
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
