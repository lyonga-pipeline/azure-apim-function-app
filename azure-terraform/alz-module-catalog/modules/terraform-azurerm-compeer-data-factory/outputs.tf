output "data_factory_id" { value = azurerm_data_factory.main_data_factory.id }
output "data_factory_name" { value = azurerm_data_factory.main_data_factory.name }
output "data_factory_identity" { value = azurerm_data_factory.main_data_factory.identity }
output "data_factory_identity_principal_id" { value = try(azurerm_data_factory.main_data_factory.identity[0].principal_id, null) }
