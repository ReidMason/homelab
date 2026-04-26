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
    enabled        = optional(bool, false)
    node_ip_prefix = optional(string, "")
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
    condition = !var.kubernetes_cluster.enabled || (
      length(trimspace(var.kubernetes_cluster.node_ip_prefix)) > 0 &&
      length(split(".", var.kubernetes_cluster.node_ip_prefix)) == 3
    )
    error_message = "When kubernetes_cluster.enabled is true, node_ip_prefix must be set to the first three IPv4 octets (e.g. 10.128.30)."
  }
  validation {
    condition = alltrue([
      for k in keys(var.kubernetes_cluster.nodes) :
      can(tonumber(k)) && tonumber(k) == floor(tonumber(k)) && tonumber(k) >= 20 && tonumber(k) < 60
    ])
    error_message = "Each nodes map key must be the last IPv4 octet as a decimal string in 20–59 (Proxmox vm_id = 100 + that number)."
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
