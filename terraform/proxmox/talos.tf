# Talos: 1 control plane + 2 workers on Proxmox. Bootstrap and kubeconfig via siderolabs/talos provider.
# Set enable_talos_cluster = true after: upload talos qcow to Proxmox (just upload-talos-image),
# DHCP reservations for talos_controlplane_ip and talos_worker_ips matching VM MACs.

locals {
  talos_on               = var.enable_talos_cluster
  talos_cluster_endpoint = local.talos_on ? format("https://%s:6443", var.talos_controlplane_ip) : ""
  talos_install_patch = yamlencode({
    machine = {
      install = {
        disk = "/dev/vda"
      }
    }
  })
}

check "talos_when_enabled" {
  assert {
    condition = !local.talos_on || (
      var.talos_controlplane_ip != "" &&
      length(var.talos_worker_ips) > 0 &&
      length(var.talos_worker_ips) == length(var.talos_worker_vm_ids)
    )
    error_message = "With enable_talos_cluster = true, set talos_controlplane_ip and talos_worker_ips (same length as talos_worker_vm_ids)."
  }
}

resource "talos_machine_secrets" "cluster" {
  count = local.talos_on ? 1 : 0

  talos_version = var.talos_version
}

data "talos_machine_configuration" "controlplane" {
  count = local.talos_on ? 1 : 0

  cluster_name     = var.talos_cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = local.talos_cluster_endpoint
  machine_secrets  = talos_machine_secrets.cluster[0].machine_secrets
  talos_version    = var.talos_version
}

data "talos_machine_configuration" "worker" {
  count = local.talos_on ? length(var.talos_worker_ips) : 0

  cluster_name     = var.talos_cluster_name
  machine_type     = "worker"
  cluster_endpoint = local.talos_cluster_endpoint
  machine_secrets  = talos_machine_secrets.cluster[0].machine_secrets
  talos_version    = var.talos_version
}

resource "proxmox_virtual_environment_vm" "talos_control_plane" {
  count = local.talos_on ? 1 : 0

  name      = "talos-cp"
  node_name = var.proxmox_node
  vm_id     = var.talos_controlplane_vm_id
  tags      = ["terraform", "talos", "kubernetes", "control-plane"]

  cpu {
    cores = var.talos_controlplane_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.talos_controlplane_memory_mb
  }

  disk {
    datastore_id = var.proxmox_datastore
    file_id      = var.talos_image_id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.talos_disk_gb
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

resource "proxmox_virtual_environment_vm" "talos_worker" {
  count = local.talos_on ? length(var.talos_worker_vm_ids) : 0

  name      = "talos-worker-${count.index + 1}"
  node_name = var.proxmox_node
  vm_id     = var.talos_worker_vm_ids[count.index]
  tags      = ["terraform", "talos", "kubernetes", "worker"]

  cpu {
    cores = var.talos_worker_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.talos_worker_memory_mb
  }

  disk {
    datastore_id = var.proxmox_datastore
    file_id      = var.talos_image_id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.talos_disk_gb
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

resource "talos_machine_configuration_apply" "control_plane" {
  count = local.talos_on ? 1 : 0

  client_configuration        = talos_machine_secrets.cluster[0].client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane[0].machine_configuration
  node                        = var.talos_controlplane_ip
  config_patches             = [local.talos_install_patch]
  apply_mode                  = "staged_if_needing_reboot"
  timeouts = { create = "25m" }

  depends_on = [proxmox_virtual_environment_vm.talos_control_plane]
}

resource "talos_machine_bootstrap" "control_plane" {
  count = local.talos_on ? 1 : 0

  client_configuration = talos_machine_secrets.cluster[0].client_configuration
  node                 = var.talos_controlplane_ip
  timeouts             = { create = "15m" }

  depends_on = [talos_machine_configuration_apply.control_plane]
}

resource "talos_machine_configuration_apply" "worker" {
  count = local.talos_on ? length(var.talos_worker_ips) : 0

  client_configuration        = talos_machine_secrets.cluster[0].client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker[count.index].machine_configuration
  node                        = var.talos_worker_ips[count.index]
  config_patches             = [local.talos_install_patch]
  apply_mode                  = "staged_if_needing_reboot"
  timeouts                    = { create = "25m" }

  depends_on = [
    talos_machine_bootstrap.control_plane,
    proxmox_virtual_environment_vm.talos_worker,
  ]
}

resource "talos_cluster_kubeconfig" "this" {
  count = local.talos_on ? 1 : 0

  client_configuration = talos_machine_secrets.cluster[0].client_configuration
  node                 = var.talos_controlplane_ip
  timeouts             = { create = "5m" }

  depends_on = [
    talos_machine_bootstrap.control_plane,
    talos_machine_configuration_apply.worker,
  ]
}

output "talos_cluster_endpoint" {
  description = "Kubernetes API URL when Talos is enabled."
  value       = local.talos_on ? local.talos_cluster_endpoint : null
}

output "talos_kubeconfig" {
  description = "kubectl config when Talos is enabled: terraform output -raw talos_kubeconfig > kubeconfig"
  value       = local.talos_on ? talos_cluster_kubeconfig.this[0].kubeconfig_raw : null
  sensitive   = true
}
