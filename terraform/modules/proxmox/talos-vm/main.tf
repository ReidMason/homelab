resource "proxmox_virtual_environment_vm" "talos_vm" {
  name      = "${var.node_type}-${var.vm_id}"
  node_name = var.proxmox_node_name
  vm_id     = var.vm_id

  bios = "ovmf"
  efi_disk {
    datastore_id = var.vm_disk_datastore_id
    type         = "4m"
  }

  machine    = "q35"
  boot_order = ["ide2", "virtio0"]

  cpu {
    cores = var.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.vm_disk_datastore_id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.disk_size_gb
    ssd          = true
  }

  cdrom {
    interface = "ide2"
    file_id   = var.iso_file_id
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
    # mac_address = trimspace(var.kubernetes_cluster.control_plane_mac_address) != "" ? trimspace(var.kubernetes_cluster.control_plane_mac_address) : null
  }

  tags = ["terraform", "kubernetes", var.node_type]
}
