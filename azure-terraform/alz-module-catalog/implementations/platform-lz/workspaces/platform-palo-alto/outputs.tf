output "public_ip_ids" {
  value = module.palo_alto.public_ip_ids
}

output "network_interface_ids" {
  value = module.palo_alto.network_interface_ids
}

output "load_balancer_ids" {
  value = module.palo_alto.load_balancer_ids
}

output "virtual_machine_ids" {
  value = module.palo_alto.virtual_machine_ids
}

output "bootstrap_storage_account_id" {
  value = module.palo_alto.bootstrap_storage_account_id
}

output "marketplace_agreement_id" {
  value = module.palo_alto.marketplace_agreement_id
}

output "vendor_vmseries" {
  value = module.palo_alto.vendor_vmseries
}
