variable "cluster_config" {
  description = "Talos cluster configuration"
  type = object({
    cluster_name   = string
    node_ip_prefix = string
    nodes = map(object({
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
    condition     = length(split(".", var.cluster_config.node_ip_prefix)) == 3
    error_message = "node_ip_prefix must be the first three IPv4 octets without a trailing dot (e.g. 10.128.30)."
  }
  validation {
    condition = alltrue([
      for k in keys(var.cluster_config.nodes) :
      can(tonumber(k)) && tonumber(k) == floor(tonumber(k)) && tonumber(k) >= 20 && tonumber(k) < 60
    ])
    error_message = "Each nodes map key must be the last IPv4 octet as a decimal string in 20–59 (Proxmox vm_id = 100 + that number)."
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

