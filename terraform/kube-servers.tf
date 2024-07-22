variable "kube_servers" {
  description = "Kubernetes servers to create"
  type = map(object({
    name = string
    desc = string
    macaddr = string
  }))
  default = {
    "130" = {
      name = "kube-controlplane-1"
      desc = "Kubetnetes server 1"
      macaddr = "6e:c8:77:4f:70:1a"
    },
    "131" = {
      name = "kube-worker-1"
      desc = "Kubetnetes server 1"
      macaddr = "82:39:c3:cf:7b:d9"
    },
    "132" = {
      name = "kube-worker-2"
      desc = "Kubetnetes server 2"
      macaddr = "82:5b:dc:cb:e6:34"
    }
  }
}

resource "proxmox_vm_qemu" "kube-server" {
  for_each = var.kube_servers

  name = each.value.name
  vmid = each.key
  desc = each.value.desc

  target_node = "ivy"

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
          iso = "local:iso/talos-amd64.iso"
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
