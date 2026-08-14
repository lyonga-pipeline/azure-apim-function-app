output "resource_group_name" {
  description = "The name of the resource group in which resources are created"
  value       = element(coalescelist(data.azurerm_resource_group.rgrp.*.name, azurerm_resource_group.rg.*.name, [""]), 0)
}

output "resource_group_id" {
  description = "The id of the resource group in which resources are created"
  value       = element(coalescelist(data.azurerm_resource_group.rgrp.*.id, azurerm_resource_group.rg.*.id, [""]), 0)
}

output "resource_group_location" {
  description = "The location of the resource group in which resources are created"
  value       = element(coalescelist(data.azurerm_resource_group.rgrp.*.location, azurerm_resource_group.rg.*.location, [""]), 0)
}

output "virtual_network_name" {
  description = "The name of the virtual network"
  value       = element(concat(azurerm_virtual_network.vnet.*.name, [""]), 0)
}

output "virtual_network_id" {
  description = "The id of the virtual network"
  value       = element(concat(azurerm_virtual_network.vnet.*.id, [""]), 0)
}

output "virtual_network_address_space" {
  description = "List of address spaces that are used the virtual network."
  value       = element(coalescelist(azurerm_virtual_network.vnet.*.address_space, [""]), 0)
}

output "subnet_ids" {
  description = "Lists the ID's of the subnets"
  value = {
    for id in keys(var.subnets) : id => azurerm_subnet.subnet[id].id
  }
}

output "subnet_address_prefixes" {
  description = "List of address prefix for subnets"
  value = {
    for sp in keys(var.subnets) : sp => azurerm_subnet.subnet[sp].address_prefixes
  }
}

output "network_security_group_ids" {
  description = "List of Network security groups and ids"
  value       = [for n in azurerm_network_security_group.nsg : n.id]
}

output "ddos_protection_plan" {
  description = "Ddos protection plan details"
  value       = var.create_ddos_plan ? element(concat(azurerm_network_ddos_protection_plan.ddos.*.id, [""]), 0) : null
}

output "network_watcher_id" {
  description = "ID of Network Watcher"
  value       = var.create_network_watcher != false ? element(concat(azurerm_network_watcher.nwatcher.*.id, [""]), 0) : null
}

// output "diagnostic_setting_id" {
//   description = "ID of the Diagnostic setting."
//   value       = azurerm_monitor_diagnostic_setting.main.id
// }