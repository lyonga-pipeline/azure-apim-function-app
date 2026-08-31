output "id" {
  description = "The container group resource ID."
  value       = azurerm_container_group.container.id
}

output "name" {
  description = "The container group name."
  value       = azurerm_container_group.container.name
}

output "ip_address" {
  description = "The IP address allocated to the container group."
  value       = azurerm_container_group.container.ip_address
}

output "fqdn" {
  description = "The FQDN of the container group when a DNS name label is assigned."
  value       = azurerm_container_group.container.fqdn
}
