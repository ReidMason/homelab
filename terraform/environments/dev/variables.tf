variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_api_token" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "proxmox_insecure" {
  type    = bool
  default = true
}
