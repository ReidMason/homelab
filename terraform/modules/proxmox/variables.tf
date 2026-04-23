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
      url = "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/v1.12.6/metal-amd64.iso"
    }
  }
}

variable "kubernetes_cluster" {
  type = object({
    enabled = optional(bool, false)
    nodes = map(object({
      mac_address = string
      ip          = string
      type        = string
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
    condition = length(distinct([
      for _, node in var.kubernetes_cluster.nodes : node.mac_address
    ])) == length(var.kubernetes_cluster.nodes)
    error_message = "Each node must have a unique mac_address."
  }
  validation {
    condition = alltrue([
      for k in keys(var.kubernetes_cluster.nodes) :
      can(tonumber(k)) && tonumber(k) == floor(tonumber(k)) && tonumber(k) >= 180 && tonumber(k) < 190
    ])
    error_message = "Each nodes map key must be a numeric vm_id string between 180 and 189 (matches talos-vm module)."
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
