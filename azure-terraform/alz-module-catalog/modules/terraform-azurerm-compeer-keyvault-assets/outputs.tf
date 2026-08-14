/**
## Azure Key Vault Secret Realated Attributes
*/
output "azurerm_key_vault_secret_id" {
  description = "The ID of the Key Vault secret."
  value       = var.create_secret ? azurerm_key_vault_secret.secret[0].id : null

}
output "azurerm_key_vault_secret_version" {
  description = "The current version of the Key Vault Secret."
  value       = var.create_secret ? azurerm_key_vault_secret.secret[0].version : null
}

/**
## Azure Key Vault Key Realated Attributes
*/
output "azurerm_key_vault_key_id" {
  description = "The ID of the Key Vault Key."
  value       = var.create_key ? azurerm_key_vault_key.key[0].id : null
}
output "azurerm_key_vault_key_resource_id" {
  description = "The (Versioned) ID for this Key Vault Key. This property points to a specific version of a Key Vault Key, as such using this won't auto-rotate values if used in other Azure Services."
  value       = var.create_key ? azurerm_key_vault_key.key[0].resource_id : null
}
output "azurerm_key_vault_key_resource_versionless_id" {
  description = "The Versionless ID of the Key Vault Key. This property allows other Azure Services (that support it) to auto-rotate their value when the Key Vault Key is updated."
  value       = var.create_key ? azurerm_key_vault_key.key[0].resource_versionless_id : null
}
output "azurerm_key_vault_key_version" {
  description = "The current version of the Key Vault Key."
  value       = var.create_key ? azurerm_key_vault_key.key[0].version : null
}
output "azurerm_key_vault_key_versionless_id" {
  description = "The Base ID of the Key Vault Key."
  value       = var.create_key ? azurerm_key_vault_key.key[0].versionless_id : null
}

/**
## Azure Key Vault Imported Certificate Realated Attributes
*/
output "azurerm_key_vault_certificate_id" {
  description = "The Key Vault Certificate ID."
  value       = var.import_certificate ? azurerm_key_vault_certificate.import_certificate[0].id : var.generate_certificate ? azurerm_key_vault_certificate.generate_certificate[0].id : null
}
output "azurerm_key_vault_certificate_secret_id" {
  description = "The ID of the associated Key Vault Secret."
  value       = var.import_certificate ? azurerm_key_vault_certificate.import_certificate[0].secret_id : var.generate_certificate ? azurerm_key_vault_certificate.generate_certificate[0].secret_id : null
}
output "azurerm_key_vault_certificate_version" {
  description = "The current version of the Key Vault Certificate."
  value       = var.import_certificate ? azurerm_key_vault_certificate.import_certificate[0].version : var.generate_certificate ? azurerm_key_vault_certificate.generate_certificate[0].version : null
}
output "azurerm_key_vault_certificate_versionless_id" {
  description = "The Base ID of the Key Vault Certificate."
  value       = var.import_certificate ? azurerm_key_vault_certificate.import_certificate[0].versionless_id : var.generate_certificate ? azurerm_key_vault_certificate.generate_certificate[0].versionless_id : null
}
output "azurerm_key_vault_certificate_versionless_secret_id" {
  description = "The Base ID of the Key Vault Secret."
  value       = var.import_certificate ? azurerm_key_vault_certificate.import_certificate[0].versionless_secret_id : var.generate_certificate ? azurerm_key_vault_certificate.generate_certificate[0].versionless_secret_id : null
}
output "azurerm_key_vault_certificate_data" {
  description = "The raw Key Vault Certificate data represented as a hexadecimal string."
  value       = var.import_certificate ? azurerm_key_vault_certificate.import_certificate[0].certificate_data : var.generate_certificate ? azurerm_key_vault_certificate.generate_certificate[0].certificate_data : null
}
output "azurerm_key_vault_certificate_attribute" {
  description = "The Key Vault Certificate Attributes."
  value       = var.import_certificate ? azurerm_key_vault_certificate.import_certificate[0].certificate_attribute : var.generate_certificate ? azurerm_key_vault_certificate.generate_certificate[0].certificate_attribute : null
}
