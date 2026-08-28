output "ddos_plan_id" { value = try(module.ddos[0].resource_id, null) }
output "vpn_gateway_id" { value = try(module.vpn_gateway[0].resource_id, null) }
output "application_gateway_id" { value = module.application_gateway.application_gateway_id }
output "network_watcher_ids" { value = { for key, watcher in azurerm_network_watcher.this : key => watcher.id } }
output "local_network_gateway_ids" { value = module.local_network_gateway.ids }
output "vpn_connection_ids" { value = { for key, connection in azurerm_virtual_network_gateway_connection.vpn : key => connection.id } }
output "route_server_public_ip_ids" { value = { for key, pip in module.route_server_public_ip : key => pip.id } }
output "route_server_ids" { value = module.route_server.ids }
output "route_server_bgp_connection_ids" { value = module.route_server.bgp_connection_ids }
output "network_watcher_flow_log_ids" { value = module.network_watcher_flow_logs.ids }
output "network_connection_monitor_ids" { value = { for key, monitor in azurerm_network_connection_monitor.this : key => monitor.id } }
