variable "node_name" {
  type = string
}

variable "iso_datastore_id" {
  type = string
}

variable "vm_disk_datastore_id" {
  type = string
}

variable "isos" {
  type = map(object({
    url = string
  }))
  default = {
    "talos-metal-amd64-v1.12.6.iso" = {
      url = "https://github.com/siderolabs/talos/releases/download/v1.12.6/metal-amd64.iso"
    }
  }
}

variable "kubernetes_cluster" {
  type = object({
    enabled = optional(bool, false)
    nodes = map(object({
      enabled   = optional(bool, true)
      ip        = string
      type      = string
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
