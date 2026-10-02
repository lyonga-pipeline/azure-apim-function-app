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
  value       = { for key, vm in azurerm_linux_virtual_machine.vm : key => vm.id }
}

output "virtual_machine_identity_principal_ids" {
  description = "System-assigned identity principal IDs for the firewall VMs, keyed by input key."
  value       = { for key, vm in azurerm_linux_virtual_machine.vm : key => try(vm.identity[0].principal_id, null) }
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

output "recovery_services_vault_ids" {
  description = "Recovery Services vault IDs keyed the same as var.recovery_services_vaults."
  value       = { for key, value in module.recovery_services_vaults : key => value.id }
}

output "recovery_services_vault_names" {
  description = "Recovery Services vault names keyed the same as var.recovery_services_vaults."
  value       = { for key, value in module.recovery_services_vaults : key => value.name }
}

output "backup_policy_vm_ids" {
  description = "VM backup policy IDs keyed <vault>.<policy>."
  value = merge({}, [
    for vault_key, vault in module.recovery_services_vaults :
    { for policy_key, id in vault.backup_policy_vm_ids : "${vault_key}.${policy_key}" => id }
  ]...)
}

output "firewall_backup_protected_vm_ids" {
  description = "Backup protected-item IDs for enrolled firewall VMs."
  value       = { for key, value in azurerm_backup_protected_vm.firewall : key => value.id }
}

output "bootstrap_key_vault_id" {
  description = "Bootstrap Key Vault ID when configured."
  value       = try(module.bootstrap_key_vault[0].id, null)
}

output "bootstrap_key_vault_uri" {
  description = "Vault URI of the bootstrap Key Vault, or null if not deployed. Reference only, never a secret value."
  value       = try(module.bootstrap_key_vault[0].vault_uri, null)
}
