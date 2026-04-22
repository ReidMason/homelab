# Proxmox connection
variable "proxmox_endpoint" {
  description = "URL of the Proxmox API, e.g. https://192.168.1.10:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the format user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification (use if Proxmox has a self-signed cert)"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name to create resources on"
  type        = string
}

variable "proxmox_datastore" {
  description = "Proxmox datastore for VM disks (e.g. local-lvm)"
  type        = string
  default     = "local-lvm"
}

# VM
variable "runner_vm_id" {
  description = "VM ID in Proxmox (must be unique)"
  type        = number
  default     = 200
}

variable "nixos_image_id" {
  description = "Proxmox file ID of the pre-uploaded NixOS cloud image (run 'just upload-image' first)"
  type        = string
  default     = "local:iso/nixos-cloud.img"
}

# --- Talos (1 control plane + 2 workers), optional ---

variable "enable_talos_cluster" {
  description = "When true, create Talos VMs and bootstrap. Requires talos_* IPs; Talos disk is downloaded on the Proxmox node unless talos_image_id is set."
  type        = bool
  default     = false
}

variable "talos_cluster_name" {
  description = "Talos / Kubernetes cluster name in generated machine config"
  type        = string
  default     = "homelab"
}

variable "talos_version" {
  description = "Talos release for machine config and secrets (match uploaded disk image, e.g. 1.12.6)"
  type        = string
  default     = "1.12.6"
}

variable "talos_image_id" {
  description = "Proxmox volid for Talos disk. Leave empty to download metal-amd64.raw.zst from Talos releases onto the node (see talos_image_datastore_id). Set e.g. local:iso/talos-metal-amd64.qcow2 to use a file you uploaded yourself."
  type        = string
  default     = ""
}

variable "talos_image_datastore_id" {
  description = "Proxmox datastore for downloaded Talos image (ISO/import content); only used when talos_image_id is empty and enable_talos_cluster is true"
  type        = string
  default     = "local"
}

variable "talos_metal_image_url" {
  description = "HTTPS URL to Talos metal-amd64.raw.zst. Empty uses GitHub for talos_version."
  type        = string
  default     = ""
}

variable "talos_controlplane_vm_id" {
  description = "Unique Proxmox VM ID for the Talos control plane"
  type        = number
  default     = 210
}

variable "talos_worker_vm_ids" {
  description = "Unique Proxmox VM IDs for Talos workers (length must match talos_worker_ips when Talos is enabled)"
  type        = list(number)
  default     = [211, 212]
}

variable "talos_controlplane_ip" {
  description = "Stable IP (DHCP reservation) for the control plane; required when enable_talos_cluster is true"
  type        = string
  default     = ""
}

variable "talos_worker_ips" {
  description = "Stable IPs (DHCP reservations) for workers, same order as talos_worker_vm_ids; required when Talos is enabled"
  type        = list(string)
  default     = []
}

variable "talos_controlplane_cores" {
  type    = number
  default = 2
}

variable "talos_controlplane_memory_mb" {
  type    = number
  default = 6144
}

variable "talos_worker_cores" {
  type    = number
  default = 4
}

variable "talos_worker_memory_mb" {
  type    = number
  default = 8192
}

variable "talos_disk_gb" {
  description = "OS disk size for each Talos VM (GiB)"
  type        = number
  default     = 40
}
