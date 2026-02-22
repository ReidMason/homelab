resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_name
  node_name = var.proxmox_node
  vm_id     = var.vm_id

  tags = var.vm_tags

  cpu {
    cores = var.vm_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.vm_memory_mb
  }

  disk {
    datastore_id = var.vm_datastore
    size         = var.vm_disk_size
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Boot from ISO if provided, otherwise leave boot order to defaults
  dynamic "cdrom" {
    for_each = var.vm_iso != null ? [var.vm_iso] : []
    content {
      enabled   = true
      file_id   = cdrom.value
      interface = "ide2"
    }
  }

  boot_order = var.vm_iso != null ? ["ide2", "virtio0"] : ["virtio0"]

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to cdrom after initial creation so you can eject the ISO manually
      cdrom,
    ]
  }
}

output "vm_id" {
  description = "The VM ID assigned in Proxmox"
  value       = proxmox_virtual_environment_vm.vm.vm_id
}

output "vm_ipv4_addresses" {
  description = "IPv4 addresses reported by the QEMU guest agent (requires agent to be running)"
  value       = proxmox_virtual_environment_vm.vm.ipv4_addresses
}
