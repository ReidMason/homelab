variable "cluster_config" {
  description = "Talos cluster configuration"
  type = object({
    cluster_name = string
    nodes = map(object({
      mac_address = string
      ip          = string
      type        = string
      enabled     = optional(bool, true)
    }))
  })
  validation {
    condition = alltrue([
      for _, node in var.cluster_config.nodes :
      contains(["control-plane", "worker"], node.type)
    ])
    error_message = "Each node must have a type of either control-plane or worker."
  }
  validation {
    condition = length(distinct([
      for _, node in var.cluster_config.nodes : node.mac_address
    ])) == length(var.cluster_config.nodes)
    error_message = "Each node must have a unique mac_address."
  }
  validation {
    condition = alltrue([
      for k in keys(var.cluster_config.nodes) :
      can(tonumber(k)) && tonumber(k) == floor(tonumber(k)) && tonumber(k) >= 180 && tonumber(k) < 190
    ])
    error_message = "Each nodes map key must be a numeric vm_id string between 180 and 189 (matches talos-vm module)."
  }
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
