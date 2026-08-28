output "bootstrap_storage_account_id" {
  value = module.bootstrap_storage.id
}

output "bootstrap_file_share_id" {
  value = try(azurerm_storage_share.bootstrap[0].id, null)
}

output "network_interface_ids" {
  value = { for key, nic in module.network_interface : key => nic.id }
}

output "public_ip_ids" {
  value = { for key, pip in module.public_ip : key => pip.id }
}

output "virtual_machine_ids" {
  value = { for key, vm in azurerm_linux_virtual_machine.palo : key => vm.id }
}

output "virtual_machine_private_ips" {
  value = { for key, vm in azurerm_linux_virtual_machine.palo : key => vm.private_ip_addresses }
}

output "backend_pool_association_ids" {
  value = { for key, association in azurerm_network_interface_backend_address_pool_association.this : key => association.id }
}

output "operational_contracts" {
  value = module.operational_contracts.contracts
}
