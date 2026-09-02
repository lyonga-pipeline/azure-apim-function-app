output "zone_id" {
  description = "The ID of the resource"
  value       = cloudflare_zone.zone.id
}

output "id" {
  description = "ID of the Cloudflare zone. Stable alias for zone_id."
  value       = cloudflare_zone.zone.id
}
output "name" {
  description = "Name of the Cloudflare zone (the domain)."
  value       = cloudflare_zone.zone.zone
}
