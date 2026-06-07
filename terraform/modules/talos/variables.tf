variable "cluster_config" {
  description = "Talos cluster configuration"
  type = object({
    cluster_name = string
    nodes = map(object({
      type        = string
      hostname    = string
      mac_address = string
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
    condition = alltrue([
      for k in keys(var.cluster_config.nodes) :
      can(tonumber(k)) && tonumber(k) == floor(tonumber(k)) && tonumber(k) >= 20 && tonumber(k) < 60
    ])
    error_message = "Each nodes map key must be the last IPv4 octet as a decimal string in 20-59 (Proxmox vm_id = 100 + that number)."
  }
  validation {
    condition = length(distinct([
      for _, node in var.cluster_config.nodes : lower(node.mac_address)
    ])) == length(var.cluster_config.nodes)
    error_message = "Each node must have a unique mac_address."
  }
  validation {
    condition = alltrue([
      for _, node in var.cluster_config.nodes :
      can(regex("^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$", node.mac_address))
    ])
    error_message = "Each mac_address must be six colon-separated hex octets (e.g. bc:24:11:aa:00:01)."
  }
  validation {
    condition = alltrue([
      for _, node in var.cluster_config.nodes : length(trimspace(node.hostname)) > 0
    ])
    error_message = "Each node must have a non-empty hostname (FQDN recommended)."
  }
  validation {
    condition = length(distinct([
      for _, node in var.cluster_config.nodes : lower(trimspace(node.hostname))
    ])) == length(var.cluster_config.nodes)
    error_message = "Each node must have a unique hostname."
  }
}

variable "talos_schematic_id" {
  type        = string
  default     = "88d1f7a5c4f1d3aba7df787c448c1d3d008ed29cfb34af53fa0df4336a56040b"
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

