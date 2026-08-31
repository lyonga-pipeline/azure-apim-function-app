output "id" { value = azurerm_automation_account.this.id }
output "name" { value = azurerm_automation_account.this.name }
output "identity" { value = azurerm_automation_account.this.identity }
output "dsc_server_endpoint" { value = azurerm_automation_account.this.dsc_server_endpoint }
output "dsc_primary_access_key" {
  value     = azurerm_automation_account.this.dsc_primary_access_key
  sensitive = true
}
output "dsc_secondary_access_key" {
  value     = azurerm_automation_account.this.dsc_secondary_access_key
  sensitive = true
}
