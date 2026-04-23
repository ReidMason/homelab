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
      url = "https://github.com/siderolabs/talos/releases/download/v1.12.6/metal-amd64.iso"
    }
  }
}

variable "kubernetes_cluster" {
  type = object({
    enabled = optional(bool, false)

    control_planes          = number
    control_plane_cores     = number
    control_plane_memory_mb = optional(number, 4096)
    control_plane_disk_gb   = optional(number, 50)

    workers          = number
    worker_cores     = optional(number, 2)
    worker_memory_mb = optional(number, 4096)
    worker_disk_gb   = optional(number, 50)
  })
}
