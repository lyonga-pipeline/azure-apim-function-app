output "id" {
  description = "Resource ID of the disk encryption set. Pass to a VM module's os_disk/data_disk disk_encryption_set_id."
  value       = azurerm_disk_encryption_set.this.id
}

output "name" {
  value = azurerm_disk_encryption_set.this.name
}

output "identity_principal_id" {
  description = "Principal ID of the disk encryption set's identity. Grant it Key Vault Crypto Service Encryption User on the source Key Vault / key before use."
  value       = azurerm_disk_encryption_set.this.identity[0].principal_id
}

output "identity_tenant_id" {
  value = azurerm_disk_encryption_set.this.identity[0].tenant_id
}
