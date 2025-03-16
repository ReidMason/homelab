resource "proxmox_vm_qemu" "virutal-machines" {
  for_each = var.kube_servers

  name = each.value.name
  vmid = each.key
  desc = each.value.desc

  target_node = var.target_node
  skip_ipv6   = true

  memory  = each.value.memory
  cpu     = "x86-64-v2-AES"
  cores   = each.value.cores
  sockets = 1

  onboot = false
  agent  = 0 // This is the quemu agent

  network {
    bridge  = "vmbr0"
    model   = "virtio"
    macaddr = each.value.macaddr
  }

  scsihw = "virtio-scsi-single"

  disks {
    ide {
      ide2 {
        cdrom {
          iso = "local:iso/talos-nocloud-amd64.iso"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size       = "20G"
          storage    = each.value.storage
          iothread   = true
          emulatessd = true
        }
      }
    }
  }
}
