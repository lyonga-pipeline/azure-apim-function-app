output "secret_ids" {
  description = "Secret resource IDs keyed by caller identity."
  value       = { for key, secret in azurerm_key_vault_secret.secret : key => secret.id }
}

output "key_ids" {
  description = "Versioned Key Vault key IDs keyed by caller identity."
  value       = { for key, value in azurerm_key_vault_key.key : key => value.id }
}

output "key_versionless_ids" {
  description = "Versionless Key Vault key IDs keyed by caller identity."
  value       = { for key, value in azurerm_key_vault_key.key : key => value.versionless_id }
}

output "certificate_ids" {
  description = "Certificate resource IDs keyed by caller identity."
  value       = { for key, value in azurerm_key_vault_certificate.certificate : key => value.id }
}

output "certificate_versionless_ids" {
  description = "Versionless certificate IDs keyed by caller identity."
  value       = { for key, value in azurerm_key_vault_certificate.certificate : key => value.versionless_id }
}
