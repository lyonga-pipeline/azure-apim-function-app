output "record_hostname" {
  description = "The FQDN of the record."
  value       = cloudflare_record.record.hostname
}

output "record_resource_id" {
  description = "The ID of this resource."
  value       = cloudflare_record.record.id
}

output "record_metadata" {
  description = "A key-value map of string metadata Cloudflare associates with the record."
  value       = cloudflare_record.record.metadata
}

output "id" {
  description = "ID of the Cloudflare DNS record. Stable alias for record_resource_id."
  value       = cloudflare_record.record.id
}
