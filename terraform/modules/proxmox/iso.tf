resource "proxmox_download_file" "iso" {
  for_each = var.isos

  node_name    = var.node_name
  datastore_id = var.iso_datastore_id
  content_type = "iso"
  url          = each.value.url
  file_name    = each.key
}
