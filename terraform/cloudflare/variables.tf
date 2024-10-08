variable "zone_id" {
  description = "The zone ID of the Cloudflare zone"
  type = string
}

variable "dns_entries" {
  description = "A list of cloudflare DNS entries"
  type = set(object({
        name = string
        content = string
        type = optional(string, "A")
        ttl = optional(number, 1)
        proxied = optional(bool, false)
  }))
}
