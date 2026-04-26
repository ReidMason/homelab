variable "cluster_config" {
  description = "Talos cluster configuration"
  type = object({
    cluster_name = string
    nodes = map(object({
      ip      = string
      type    = string
      enabled = optional(bool, true)
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

variable "kubernetes_version" {
  type        = string
  description = "The version of Kubernetes to use"
}

variable "install_disk" {
  type        = string
  default     = "/dev/vda"
  description = "Block device for Talos install (e.g. VirtIO on Proxmox)"
}

variable "nameservers" {
  type        = list(string)
  default     = ["10.128.0.1", "1.1.1.1"]
  description = "DNS resolvers for Talos machine config"
}

