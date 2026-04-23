variable "node_name" {
  type = string
}

variable "iso_datastore_id" {
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
