output "ids" {
  description = "Local network gateway IDs keyed by input key."
  value       = { for key, gateway in azurerm_local_network_gateway.this : key => gateway.id }
}
