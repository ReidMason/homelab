module "kubernetes_nodes" {
  for_each = var.kubernetes_cluster.enabled ? {
    for k, n in var.kubernetes_cluster.nodes : k => n
    if coalesce(n.enabled, true)
  } : {}

  source               = "./talos-vm"
  node_type            = each.value.type
  vm_id                = tonumber(each.key)
  proxmox_node_name    = var.node_name
  vm_disk_datastore_id = var.vm_disk_datastore_id
  iso_file_id          = proxmox_download_file.iso["talos-nocloud.iso"].id
  mac_address          = each.value.mac_address

  cores = coalesce(
    try(each.value.cores, null),
    each.value.type == "control-plane" ? var.control_plane_defaults.cores : var.worker_defaults.cores
  )
  memory_mb = coalesce(
    try(each.value.memory_mb, null),
    each.value.type == "control-plane" ? var.control_plane_defaults.memory_mb : var.worker_defaults.memory_mb
  )
  disk_size_gb = coalesce(
    try(each.value.disk_gb, null),
    each.value.type == "control-plane" ? var.control_plane_defaults.disk_gb : var.worker_defaults.disk_gb
  )
}
