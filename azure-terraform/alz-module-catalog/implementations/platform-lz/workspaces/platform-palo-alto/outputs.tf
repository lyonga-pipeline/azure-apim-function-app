output "public_ip_ids" {
  description = "Public IP IDs keyed by input key."
  value       = module.palo_alto.public_ip_ids
}

output "network_interface_ids" {
  description = "NIC IDs keyed by input key."
  value       = module.palo_alto.network_interface_ids
}

output "load_balancer_ids" {
  description = "Load balancer IDs keyed by input key."
  value       = module.palo_alto.load_balancer_ids
}

output "virtual_machine_ids" {
  description = "Palo Alto VM IDs keyed by input key."
  value       = module.palo_alto.virtual_machine_ids
}

output "virtual_machine_identity_principal_ids" {
  description = "System-assigned identity principal IDs for the firewall VMs, keyed by input key."
  value       = module.palo_alto.virtual_machine_identity_principal_ids
}

output "bootstrap_storage_account_id" {
  description = "Bootstrap storage account ID when configured."
  value       = module.palo_alto.bootstrap_storage_account_id
}

output "bootstrap_storage_share_ids" {
  description = "Bootstrap file share resource IDs keyed by share name."
  value       = module.palo_alto.bootstrap_storage_share_ids
}

output "marketplace_agreement_id" {
  description = "Palo Alto VM-Series image agreement ID when managed by this pattern."
  value       = module.palo_alto.marketplace_agreement_id
}

output "bootstrap_key_vault_id" {
  description = "Bootstrap Key Vault ID when configured."
  value       = module.palo_alto.bootstrap_key_vault_id
}

output "bootstrap_key_vault_uri" {
  description = "Vault URI of the bootstrap Key Vault, or null if not deployed. Reference only, never a secret value."
  value       = module.palo_alto.bootstrap_key_vault_uri
}
