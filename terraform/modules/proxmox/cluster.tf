locals {
  kubernetes_nodes_for_each = var.kubernetes_cluster.enabled ? {
    for oct, n in var.kubernetes_cluster.nodes :
    "${var.kubernetes_cluster.node_ip_prefix}.${oct}" => n
    if coalesce(n.enabled, true)
  } : {}
}

module "kubernetes_nodes" {
  for_each = local.kubernetes_nodes_for_each

  source               = "./talos-vm"
  node_type            = each.value.type
  vm_id                = 100 + tonumber(element(split(".", each.key), 3))
  proxmox_node_name    = var.node_name
  vm_disk_datastore_id = var.vm_disk_datastore_id
  iso_file_id          = proxmox_download_file.iso["talos-nocloud.iso"].id

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
