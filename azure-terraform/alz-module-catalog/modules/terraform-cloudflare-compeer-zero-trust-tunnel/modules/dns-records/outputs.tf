output "ids" {
  description = "Cloudflare DNS record IDs with caller-supplied keys preserved."
  value       = { for key, record in cloudflare_record.record : key => record.id }
}
