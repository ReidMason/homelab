data "http" "github_keys" {
  url = "https://github.com/${var.github_username}.keys"
}

resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    data      = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      ssh_public_key = data.http.github_keys.response_body
    })
    file_name = "runner-cloud-init.yaml"
  }
}

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
    dedicated = 2048
  }

  disk {
    datastore_id = var.proxmox_datastore
    file_id      = var.nixos_image_id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
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
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
  }
}

output "runner_ip" {
  value = proxmox_virtual_environment_vm.runner.ipv4_addresses[0][0]
}
