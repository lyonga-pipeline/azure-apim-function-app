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

output "bootstrap_storage_account_id" {
  description = "Bootstrap storage account ID when configured."
  value       = try(module.bootstrap_storage[0].id, null)
}

output "marketplace_agreement_id" {
  description = "Palo Alto Marketplace agreement ID when managed by this pattern."
  value       = try(azurerm_marketplace_agreement.palo_alto[0].id, null)
}

output "vendor_vmseries" {
  description = "Palo Alto Networks swfw-modules VM-Series outputs keyed by firewall key."
  value = {
    for key, firewall in module.vendor_vmseries : key => {
      mgmt_ip_address = firewall.mgmt_ip_address
      interfaces      = firewall.interfaces
      principal_id    = firewall.principal_id
    }
  }
}
