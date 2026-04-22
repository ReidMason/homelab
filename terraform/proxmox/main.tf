resource "proxmox_virtual_environment_vm" "runner" {
  name      = "github-runner"
  node_name = var.proxmox_node
  vm_id     = var.runner_vm_id
  tags      = ["terraform", "runner"]

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = var.proxmox_datastore
    import_from  = var.nixos_image_id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 50
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
    # Cap wait when guest agent is down (default is 15m and feels like a hang on refresh).
    timeout = "2m"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}

output "runner_ip" {
  value = [
    for addr in flatten(proxmox_virtual_environment_vm.runner.ipv4_addresses) :
    addr if addr != "127.0.0.1"
  ][0]
}
