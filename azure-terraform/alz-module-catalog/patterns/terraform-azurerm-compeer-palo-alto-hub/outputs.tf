output "public_ip_ids" {
  description = "Public IP IDs keyed by input key."
  value       = { for key, public_ip in module.public_ips : key => public_ip.id }
}

output "network_interface_ids" {
  description = "NIC IDs keyed by input key."
  value       = { for key, nic in module.network_interfaces : key => nic.id }
}

output "load_balancer_ids" {
  description = "Load balancer IDs keyed by input key."
  value       = { for key, lb in module.load_balancers : key => lb.id }
}

output "virtual_machine_ids" {
  description = "Palo Alto VM IDs keyed by input key."
  value       = { for key, vm in azurerm_linux_virtual_machine.this : key => vm.id }
}

output "virtual_machine_identity_principal_ids" {
  description = "System-assigned identity principal IDs for the firewall VMs, keyed by input key."
  value       = { for key, vm in azurerm_linux_virtual_machine.this : key => try(vm.identity[0].principal_id, null) }
}

output "bootstrap_storage_account_id" {
  description = "Bootstrap storage account ID when configured."
  value       = try(module.bootstrap_storage[0].id, null)
}

output "bootstrap_storage_share_ids" {
  description = "Bootstrap file share resource IDs keyed by share name."
  value       = { for key, share in azurerm_storage_share.bootstrap : key => share.id }
}

output "marketplace_agreement_id" {
  description = "Palo Alto VM-Series image agreement ID when managed by this pattern."
  value       = try(azurerm_marketplace_agreement.palo_alto[0].id, null)
}

output "bootstrap_key_vault_id" {
  description = "Bootstrap Key Vault ID when configured."
  value       = try(module.bootstrap_key_vault[0].id, null)
}

output "bootstrap_key_vault_uri" {
  value = try(module.bootstrap_key_vault[0].vault_uri, null)
}
