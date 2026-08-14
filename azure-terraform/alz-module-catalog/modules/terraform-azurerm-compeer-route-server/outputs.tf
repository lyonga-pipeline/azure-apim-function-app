output "ids" {
  description = "Route server IDs keyed by input key."
  value       = { for key, route_server in azurerm_route_server.this : key => route_server.id }
}

output "bgp_connection_ids" {
  description = "Route server BGP connection IDs keyed by generated key."
  value       = { for key, connection in azurerm_route_server_bgp_connection.this : key => connection.id }
}
