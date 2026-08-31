output "eventgrid_id" { value = azurerm_eventgrid_topic.main.id }
output "eventgrid_endpoint" { value = azurerm_eventgrid_topic.main.endpoint }
output "eventgrid_primary_access_key" {
  value     = azurerm_eventgrid_topic.main.primary_access_key
  sensitive = true
}
output "eventgrid_secondary_access_key" {
  value     = azurerm_eventgrid_topic.main.secondary_access_key
  sensitive = true
}
output "principal_id" { value = try(azurerm_eventgrid_topic.main.identity[0].principal_id, null) }
