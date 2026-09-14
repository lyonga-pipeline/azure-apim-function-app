output "id" {
  description = "Resource ID of the DDoS protection plan."
  value       = azurerm_network_ddos_protection_plan.plan.id
}
output "name" {
  description = "Name of the DDoS protection plan."
  value       = azurerm_network_ddos_protection_plan.plan.name
}
