resource "proxmox_virtual_environment_vm" "control_plane" {
  count = var.kubernetes_cluster.enabled ? var.kubernetes_cluster.control_planes : 0

  name      = "control-plane-${count.index + 1}"
  node_name = var.node_name
  vm_id     = 150 + count.index + 1

  bios = "ovmf"
  efi_disk {
    datastore_id = var.vm_disk_datastore_id
    type         = "4m"
  }

  machine    = "q35"
  boot_order = ["ide2", "virtio0"]

  cpu {
    cores = var.kubernetes_cluster.control_plane_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.kubernetes_cluster.control_plane_memory_mb
  }

  disk {
    datastore_id = var.vm_disk_datastore_id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.kubernetes_cluster.control_plane_disk_gb
    ssd          = true
  }

  cdrom {
    interface = "ide2"
    file_id   = proxmox_download_file.iso["talos-metal-amd64-v1.12.6.iso"].id
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
    # mac_address = trimspace(var.kubernetes_cluster.control_plane_mac_address) != "" ? trimspace(var.kubernetes_cluster.control_plane_mac_address) : null
  }

  tags = ["terraform", "kubernetes", "control-plane"]
}

# resource "proxmox_virtual_environment_vm" "worker" {
#   count = var.kubernetes_cluster.enabled ? var.kubernetes_cluster.workers : 0

#   name      = "worker-${count.index + 1}"
#   node_name = var.node_name
#   vm_id     = 160 + count.index + 1

#   cpu {
#     cores = var.kubernetes_cluster.worker_cores
#   }

#   memory {
#     dedicated = var.kubernetes_cluster.worker_memory_mb
#   }

#   disk {
#     datastore_id = var.iso_datastore_id
#     interface    = "virtio0"
#     iothread     = true
#     discard      = "on"
#     size         = var.kubernetes_cluster.worker_disk_gb
#     ssd          = true
#   }

#   cdrom {
#     interface = "ide2"
#     file_id   = proxmox_download_file.iso["talos-metal-amd64-v1.12.6.iso"].id
#   }

#   tags = ["terraform", "kubernetes", "worker"]
# }
