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
