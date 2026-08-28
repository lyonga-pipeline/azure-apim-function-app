output "domain_controller_ids" {
  value = { for key, controller in module.domain_controller : key => controller.id }
}

output "domain_controller_private_ips" {
  value = { for key, controller in module.domain_controller : key => controller.private_ips }
}

output "network_interface_ids" {
  value = { for key, nic in module.network_interface : key => nic.id }
}

output "data_disk_ids" {
  value = { for key, disk in azurerm_managed_disk.data : key => disk.id }
}

output "domain_join_extension_ids" {
  value = { for key, extension in module.domain_join : key => extension.id }
}

output "operational_contracts" {
  value = module.operational_contracts.contracts
}
