output "resource_group_name" {
  value = try(module.directory_services[0].resource_group_name, null)
}

output "network_interface_ids" {
  value = try(module.directory_services[0].network_interface_ids, {})
}

output "network_interface_private_ip_addresses" {
  value = try(module.directory_services[0].network_interface_private_ip_addresses, {})
}

output "domain_controller_ids" {
  value = try(module.directory_services[0].domain_controller_ids, {})
}

output "domain_controller_names" {
  value = try(module.directory_services[0].domain_controller_names, {})
}

output "domain_controller_private_ips" {
  value = try(module.directory_services[0].domain_controller_private_ips, {})
}

output "data_disk_ids" {
  value = try(module.directory_services[0].data_disk_ids, {})
}

output "diagnostic_setting_ids" {
  value = try(module.directory_services[0].diagnostic_setting_ids, {})
}

output "domain_join_extension_ids" {
  value = try(module.directory_services[0].domain_join_extension_ids, {})
}

output "operational_contracts" {
  value = try(module.directory_services[0].operational_contracts, {})
}
