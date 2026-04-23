locals {
  talos_iso_url = "https://factory.talos.dev/image/${var.talos_schematic_id}/v${var.talos_version}/nocloud-${var.talos_arch}.iso"
}

resource "proxmox_download_file" "iso" {
  for_each = merge(var.isos, {
    "talos-nocloud.iso" = {
      url = local.talos_iso_url
    }
  })

  node_name    = var.node_name
  datastore_id = var.iso_datastore_id
  content_type = "iso"
  url          = each.value.url
  file_name    = each.key
}
