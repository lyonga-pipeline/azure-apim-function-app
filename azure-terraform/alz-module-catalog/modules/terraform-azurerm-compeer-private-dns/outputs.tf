output "zone_ids" {
  description = "Map of zone name => zone resource ID."
  value       = { for k, z in azurerm_private_dns_zone.this : k => z.id }
}

output "zone_names" {
  description = "Map of zone key => Azure zone name."
  value       = { for k, z in azurerm_private_dns_zone.this : k => z.name }
}

output "zones" {
  description = "Map of zone name => { id, name, number_of_record_sets }."
  value = {
    for k, z in azurerm_private_dns_zone.this : k => {
      id                    = z.id
      name                  = z.name
      number_of_record_sets = z.number_of_record_sets
    }
  }
}

output "vnet_link_ids" {
  description = "Map of \"zone/link\" composite key => VNet link resource ID."
  value       = { for k, l in azurerm_private_dns_zone_virtual_network_link.this : k => l.id }
}
