# Talos: 1 control plane + N workers on Proxmox. Bootstrap and kubeconfig via siderolabs/talos provider.
# Same pattern as kubernetes-cluster-v2/proxmox-vms (telmate): empty OS disk + boot ISO on IDE; no import_from / no Proxmox SSH.
# UEFI (OVMF + efidisk): Talos ISO is not SeaBIOS-bootable. No Proxmox cloud-init block — it would occupy ide2 and evict the Talos CD.
# Define nodes in var.talos_controlplanes / var.talos_workers (ip + optional mac); match DHCP reservations on the router.

locals {
  talos_on = var.enable_talos_cluster
  # Safe indexing: only treat as valid CP when exactly one control plane object is defined.
  talos_cp = (
    local.talos_on && length(var.talos_controlplanes) == 1
  ) ? var.talos_controlplanes[0] : null
  talos_cluster_endpoint  = local.talos_cp != null && trimspace(local.talos_cp.ip) != "" ? format("https://%s:6443", local.talos_cp.ip) : ""
  talos_install_image_tag = startswith(var.talos_version, "v") ? var.talos_version : "v${var.talos_version}"
  talos_version_for_url   = trimprefix(local.talos_install_image_tag, "v")
  talos_iso_download_url = trimspace(var.talos_metal_image_url) != "" ? trimspace(var.talos_metal_image_url) : format(
    "https://github.com/siderolabs/talos/releases/download/%s/metal-amd64.iso",
    local.talos_install_image_tag,
  )
  talos_install_patch = yamlencode({
    machine = {
      install = {
        disk  = "/dev/vda"
        image = "ghcr.io/siderolabs/installer:${local.talos_install_image_tag}"
      }
    }
  })
  # Resources that need a valid control plane node use this (avoids partial apply with invalid lists).
  talos_ready = local.talos_cp != null && trimspace(local.talos_cp.ip) != ""
  # Pre-uploaded boot ISO volid (e.g. local:iso/talos-metal-amd64.iso); if empty, proxmox_download_file supplies one.
  talos_boot_iso_file_id = !local.talos_ready ? null : (
    trimspace(var.talos_image_id) != "" ? trimspace(var.talos_image_id) : proxmox_download_file.talos_metal[0].id
  )
}

resource "proxmox_download_file" "talos_metal" {
  count = local.talos_ready && trimspace(var.talos_image_id) == "" ? 1 : 0

  content_type        = "iso"
  datastore_id        = var.talos_image_datastore_id
  node_name           = var.proxmox_node
  url                 = local.talos_iso_download_url
  file_name           = "talos-metal-amd64-${local.talos_version_for_url}.iso"
  upload_timeout      = 1800
  overwrite           = false
  overwrite_unmanaged = true
  verify              = true
}

check "talos_when_enabled" {
  assert {
    condition = !local.talos_on || (
      length(var.talos_controlplanes) == 1 &&
      trimspace(var.talos_controlplanes[0].ip) != ""
    )
    error_message = "With enable_talos_cluster = true, set talos_controlplanes to exactly one object with a non-empty ip (and vm_id)."
  }
}

check "talos_vm_ids_unique" {
  assert {
    condition = !local.talos_on || length(distinct(concat(
      [for cp in var.talos_controlplanes : cp.vm_id],
      [for w in var.talos_workers : w.vm_id],
    ))) == (length(var.talos_controlplanes) + length(var.talos_workers))
    error_message = "Talos vm_id values must be unique across talos_controlplanes and talos_workers."
  }
}

check "talos_worker_ips_set" {
  assert {
    condition = !local.talos_on || alltrue([
      for w in var.talos_workers : trimspace(w.ip) != ""
    ])
    error_message = "Each talos_workers entry must have a non-empty ip."
  }
}

resource "talos_machine_secrets" "cluster" {
  count = local.talos_ready ? 1 : 0

  talos_version = var.talos_version
}

data "talos_machine_configuration" "controlplane" {
  count = local.talos_ready ? 1 : 0

  cluster_name     = var.talos_cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = local.talos_cluster_endpoint
  machine_secrets  = talos_machine_secrets.cluster[0].machine_secrets
  talos_version    = var.talos_version
}

data "talos_machine_configuration" "worker" {
  count = local.talos_ready ? length(var.talos_workers) : 0

  cluster_name     = var.talos_cluster_name
  machine_type     = "worker"
  cluster_endpoint = local.talos_cluster_endpoint
  machine_secrets  = talos_machine_secrets.cluster[0].machine_secrets
  talos_version    = var.talos_version
}

resource "proxmox_virtual_environment_vm" "talos_control_plane" {
  count = local.talos_ready ? 1 : 0

  name      = "talos-cp"
  node_name = var.proxmox_node
  vm_id     = local.talos_cp.vm_id
  tags      = ["terraform", "talos", "kubernetes", "control-plane"]

  # Talos ISO is UEFI-only; SeaBIOS shows "no bootable device". OVMF needs an efidisk.
  bios = "ovmf"
  efi_disk {
    datastore_id = var.proxmox_datastore
    type         = "4m"
  }

  machine    = "q35"
  boot_order = ["ide2", "virtio0"]

  cpu {
    cores = var.talos_controlplane_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.talos_controlplane_memory_mb
  }

  cdrom {
    interface = "ide2"
    file_id   = local.talos_boot_iso_file_id
  }

  disk {
    datastore_id = var.proxmox_datastore
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.talos_disk_gb
    ssd          = true
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = trimspace(local.talos_cp.mac_address) != "" ? trimspace(local.talos_cp.mac_address) : null
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
    timeout = "2m"
  }
}

resource "proxmox_virtual_environment_vm" "talos_worker" {
  count = local.talos_ready ? length(var.talos_workers) : 0

  name      = "talos-worker-${count.index + 1}"
  node_name = var.proxmox_node
  vm_id     = var.talos_workers[count.index].vm_id
  tags      = ["terraform", "talos", "kubernetes", "worker"]

  bios = "ovmf"
  efi_disk {
    datastore_id = var.proxmox_datastore
    type         = "4m"
  }

  machine    = "q35"
  boot_order = ["ide2", "virtio0"]

  cpu {
    cores = var.talos_worker_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.talos_worker_memory_mb
  }

  cdrom {
    interface = "ide2"
    file_id   = local.talos_boot_iso_file_id
  }

  disk {
    datastore_id = var.proxmox_datastore
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.talos_disk_gb
    ssd          = true
  }

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = trimspace(var.talos_workers[count.index].mac_address) != "" ? trimspace(var.talos_workers[count.index].mac_address) : null
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
    timeout = "2m"
  }
}

resource "talos_machine_configuration_apply" "control_plane" {
  count = local.talos_ready ? 1 : 0

  client_configuration        = talos_machine_secrets.cluster[0].client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane[0].machine_configuration
  node                        = local.talos_cp.ip
  config_patches              = [local.talos_install_patch]
  # "staged_if_needing_reboot" can flip resolved_apply_mode between plan and apply (provider bug / inconsistent final plan).
  apply_mode = "staged"
  timeouts   = { create = "25m" }

  depends_on = [proxmox_virtual_environment_vm.talos_control_plane]
}

resource "talos_machine_bootstrap" "control_plane" {
  count = local.talos_ready ? 1 : 0

  client_configuration = talos_machine_secrets.cluster[0].client_configuration
  node                 = local.talos_cp.ip
  timeouts             = { create = "15m" }

  depends_on = [talos_machine_configuration_apply.control_plane]
}

resource "talos_machine_configuration_apply" "worker" {
  count = local.talos_ready ? length(var.talos_workers) : 0

  client_configuration        = talos_machine_secrets.cluster[0].client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker[count.index].machine_configuration
  node                        = var.talos_workers[count.index].ip
  config_patches              = [local.talos_install_patch]
  apply_mode                  = "staged"
  timeouts                    = { create = "25m" }

  depends_on = [
    talos_machine_bootstrap.control_plane,
    proxmox_virtual_environment_vm.talos_worker,
  ]
}

resource "talos_cluster_kubeconfig" "this" {
  count = local.talos_ready ? 1 : 0

  client_configuration = talos_machine_secrets.cluster[0].client_configuration
  node                 = local.talos_cp.ip
  timeouts             = { create = "5m" }

  depends_on = [
    talos_machine_bootstrap.control_plane,
    talos_machine_configuration_apply.worker,
  ]
}

output "talos_cluster_endpoint" {
  description = "Kubernetes API URL when Talos is enabled."
  value       = local.talos_ready ? local.talos_cluster_endpoint : null
}

output "talos_kubeconfig" {
  description = "kubectl config when Talos is enabled: terraform output -raw talos_kubeconfig > kubeconfig"
  value       = local.talos_ready ? talos_cluster_kubeconfig.this[0].kubeconfig_raw : null
  sensitive   = true
}
