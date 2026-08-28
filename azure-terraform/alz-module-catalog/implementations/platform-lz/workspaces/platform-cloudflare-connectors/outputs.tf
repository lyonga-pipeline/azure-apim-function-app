output "resource_group_name" {
  value = try(module.cloudflare_connectors[0].resource_group_name, null)
}

output "network_interface_ids" {
  value = try(module.cloudflare_connectors[0].network_interface_ids, {})
}

output "network_interface_private_ip_addresses" {
  value = try(module.cloudflare_connectors[0].network_interface_private_ip_addresses, {})
}

output "connector_vm_ids" {
  value = try(module.cloudflare_connectors[0].connector_vm_ids, {})
}

output "connector_vm_private_ips" {
  value = try(module.cloudflare_connectors[0].connector_vm_private_ips, {})
}

output "connector_vm_principal_ids" {
  value = try(module.cloudflare_connectors[0].connector_vm_principal_ids, {})
}

output "extension_ids" {
  value = try(module.cloudflare_connectors[0].extension_ids, {})
}

output "diagnostic_setting_ids" {
  value = try(module.cloudflare_connectors[0].diagnostic_setting_ids, {})
}

output "operational_contracts" {
  value = try(module.cloudflare_connectors[0].operational_contracts, {})
}
