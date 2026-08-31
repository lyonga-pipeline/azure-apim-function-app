output "id" {
  description = "Resource ID of the application certificate."
  value       = azuread_application_certificate.ad_application_certificate.id
}

output "key_id" {
  description = "Key ID of the application certificate."
  value       = azuread_application_certificate.ad_application_certificate.key_id
}

output "application_id" {
  description = "Application resource ID the certificate is attached to."
  value       = local.application_id
}
