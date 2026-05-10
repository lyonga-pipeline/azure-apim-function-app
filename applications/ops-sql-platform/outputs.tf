output "resource_group_name" {
  value = module.resource_group.name
}

output "windows_vm_name" {
  value = module.windows_vm.name
}

output "sql_server_fqdn" {
  value = module.sql_server.fully_qualified_domain_name
}

output "load_balancer_public_ip" {
  value = module.load_balancer_public_ip.ip_address
}
