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
    condition     = length([for s in var.kube_servers : s if s.type == "controlplane"]) > 0
    error_message = "At least one controlplane must be defined"
  }
  validation {
    condition     = length([for s in var.kube_servers : s if s.type == "worker"]) > 0
    error_message = "At least one worker must be defined"
  }
  validation {
    condition     = alltrue([for k, v in var.kube_servers : can(regex("^[0-9]+$", k))])
    error_message = "Server keys must be numeric"
  }
  validation {
    condition     = alltrue([for k, v in var.kube_servers : can(regex("^(controlplane|worker)$", v.type))])
    error_message = "Server type must be controlplane or worker"
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
