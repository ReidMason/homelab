resource "proxmox_vm_qemu" "kube-server-1" {
  name = "kube-server-1"
  target_node = "ivy"
  desc = "Kubetnetes server 1"
  vmid = 110

  memory = 4096
  cpu = "host"
  cores = 4
  sockets = 1

  onboot = false
  agent = 1

  network {
    bridge = "vmbr0"
    model = "virtio"
    macaddr = "6e:c8:77:4f:70:1a"
  }
  
  scsihw = "virtio-scsi-single"

  disks {
    ide {
      ide2 {
        cdrom {
          iso = "local:iso/talos-amd64.iso"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size = "20G"
          storage = "vm-storage"
          iothread = 1
        }
      }
    }
  }
}
