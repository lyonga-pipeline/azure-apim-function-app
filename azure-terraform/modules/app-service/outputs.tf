output "id" {
  value = local.app_service_id
}

output "name" {
  value = local.app_service_name
}

output "default_hostname" {
  value = local.default_hostname
}

output "service_plan_id" {
  value = azurerm_service_plan.this.id
}

output "service_plan_name" {
  value = azurerm_service_plan.this.name
}

output "identity" {
  value = local.identity
}

output "outbound_ip_addresses" {
  value = local.outbound_ips
}

output "vnet_integration_id" {
  value = try(azurerm_app_service_virtual_network_swift_connection.this[0].id, null)
}
