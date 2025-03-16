variable "kube_servers" {
  description = "Kubernetes servers to create"
  type = map(object({
    name = string
    type = string
    ip   = string
  }))
  validation {
    condition     = alltrue([for k, v in var.kube_servers : can(regex("^(controlplane|worker)$", v.type))])
    error_message = "Server type must be controlplane or worker"
  }
  validation {
    condition     = length([for s in var.kube_servers : s if s.type == "controlplane"]) > 0
    error_message = "At least one controlplane must be defined"
  }
  validation {
    condition     = length([for s in var.kube_servers : s if s.type == "worker"]) > 0
    error_message = "At least one worker must be defined"
  }
}
