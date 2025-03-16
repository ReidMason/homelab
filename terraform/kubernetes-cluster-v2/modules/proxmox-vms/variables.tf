variable "kube_servers" {
  description = "Kubernetes servers to create"
  type = map(object({
    name    = string
    desc    = string
    macaddr = string
    type    = string
    cores   = number
    memory  = number
    storage = string
    ip      = string
  }))
  validation {
    condition     = alltrue([for k, v in var.kube_servers : can(regex("^[0-9]+$", k))])
    error_message = "Server keys must be numeric"
  }
}

variable "target_node" {
  description = "Proxmox node to create the virtual machines on"
  type        = string
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}
