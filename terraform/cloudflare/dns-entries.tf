resource "cloudflare_record" "dns_entries" {
  for_each = {
    for index, dns_entry in var.dns_entries:
      dns_entry.name => dns_entry
  }

  zone_id = var.zone_id
  name = each.value.name
  content = each.value.content
  type = each.value.type
  ttl = each.value.ttl
}
