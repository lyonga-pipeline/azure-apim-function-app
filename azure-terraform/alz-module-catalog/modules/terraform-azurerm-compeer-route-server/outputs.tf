output "ids" {
  description = "Route server IDs keyed by input key."
  value       = { for key, route_server in azurerm_route_server.this : key => route_server.id }
}

output "names" {
  description = "Route server names keyed by input key."
  value       = { for key, route_server in azurerm_route_server.this : key => route_server.name }
}

output "resource_group_names" {
  description = "Route server resource group names keyed by input key."
  value       = { for key, route_server in azurerm_route_server.this : key => route_server.resource_group_name }
}

output "route_servers" {
  description = "Route server attributes keyed by input key for downstream composition."
  value = {
    for key, route_server in azurerm_route_server.this : key => {
      id                               = route_server.id
      name                             = route_server.name
      resource_group_name              = route_server.resource_group_name
      location                         = route_server.location
      subnet_id                        = route_server.subnet_id
      public_ip_address_id             = route_server.public_ip_address_id
      branch_to_branch_traffic_enabled = route_server.branch_to_branch_traffic_enabled
    }
  }
}

output "bgp_connection_ids" {
  description = "Route server BGP connection IDs keyed by generated key."
  value       = { for key, connection in azurerm_route_server_bgp_connection.this : key => connection.id }
}

output "bgp_connections" {
  description = "Route server BGP connection attributes keyed by generated key."
  value = {
    for key, connection in azurerm_route_server_bgp_connection.this : key => {
      id              = connection.id
      name            = connection.name
      route_server_id = connection.route_server_id
      peer_asn        = connection.peer_asn
      peer_ip         = connection.peer_ip
    }
  }
}
