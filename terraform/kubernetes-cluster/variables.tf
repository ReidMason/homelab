variable "kube_servers" {
  description = "Kubernetes servers to create"
  type = map(object({
    name = string
    desc = string
    macaddr = string
    type = string
    ip = string
  }))
  validation {
    condition = length([for s in var.kube_servers : s if s.type == "controlplane"]) > 0
    error_message = "At least one controlplane must be defined"
  }
  validation {
    condition = length([for s in var.kube_servers : s if s.type == "worker"]) > 0
    error_message = "At least one worker must be defined"
  }
  validation {
    condition = alltrue([for k, v in var.kube_servers : can(regex("^[0-9]+$", k))])
    error_message = "Server keys must be numeric"
  }
  validation {
    condition = alltrue([for k, v in var.kube_servers : can(regex("^(controlplane|worker)$", v.type))])
    error_message = "Server type must be controlplane or worker"
  }
  default = {
    "130" = {
      name = "kube-controlplane-1"
      desc = "Kubetnetes server 1"
      macaddr = "6e:c8:77:4f:70:1a"
      ip = "10.128.100.130"
      type = "controlplane"
    },
    "131" = {
      name = "kube-worker-1"
      desc = "Kubetnetes worker 1"
      macaddr = "82:39:c3:cf:7b:d9"
      ip = "10.128.100.131"
      type = "worker"
    },
    "132" = {
      name = "kube-worker-2"
      desc = "Kubetnetes worker 2"
      macaddr = "82:5b:dc:cb:e6:34"
      ip = "10.128.100.132"
      type = "worker"
    }
  }
}
