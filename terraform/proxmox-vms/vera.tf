resource "proxmox_vm_qemu" "vera" {
  name = "vera-v2"
  vmid = "101"
  desc = "Vera - main server"

  target_node = "ivy"
  skip_ipv6 = true

  memory = 16384
  cpu = "x86-64-v2-AES"
  cores = 12
  sockets = 1

  onboot = false
  agent = 1

  network {
    bridge = "vmbr0"
    model = "virtio"
    macaddr = "ba:e3:88:14:95:b4"
  }
  
  scsihw = "virtio-scsi-single"

  disks {
    ide {
      ide2 {
        cdrom {
          iso = "local:iso/nixos-gnome-24.05.1695.dd457de7e08c-x86_64-linux.iso"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size = "200G"
          storage = "vm-storage"
          iothread = true
          emulatessd = true
        }
      }
    }
  }
}
