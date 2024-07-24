resource "proxmox_vm_qemu" "kube-server" {
  for_each = var.kube_servers

  name = each.value.name
  vmid = each.key
  desc = each.value.desc

  target_node = "ivy"
  skip_ipv6 = true

  memory = 4096
  cpu = "x86-64-v2-AES"
  cores = 4
  sockets = 1

  onboot = false
  agent = 1

  network {
    bridge = "vmbr0"
    model = "virtio"
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
          size = "20G"
          storage = "vm-storage"
          iothread = true
          emulatessd = true
        }
      }
    }
  }
}
