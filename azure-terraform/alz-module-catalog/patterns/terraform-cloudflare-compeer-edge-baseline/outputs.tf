output "zone_ids" {
  description = "Cloudflare zone IDs keyed by input key."
  value       = { for key, zone in cloudflare_zone.this : key => zone.id }
}

output "record_ids" {
  description = "Cloudflare record IDs keyed by input key."
  value       = { for key, record in cloudflare_record.this : key => record.id }
}

output "ruleset_ids" {
  description = "Cloudflare ruleset IDs keyed by input key."
  value       = { for key, ruleset in cloudflare_ruleset.this : key => ruleset.id }
}
