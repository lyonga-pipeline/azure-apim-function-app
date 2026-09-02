output "ids" {
  description = "Map of caller-supplied key to private DNS zone resource ID."
  value       = { for key, value in azurerm_private_dns_zone.this : key => value.id }
}
output "names" {
  description = "Map of caller-supplied key to private DNS zone name."
  value       = { for key, value in azurerm_private_dns_zone.this : key => value.name }
}
output "resource_group_names" {
  description = "Map of caller-supplied key to the resource group name hosting each zone."
  value       = { for key, value in azurerm_private_dns_zone.this : key => value.resource_group_name }
}
output "zones" {
  description = "Map of caller-supplied key to zone attributes (id, name, resource_group_name), for private endpoint DNS zone groups."
  value = {
    for key, value in azurerm_private_dns_zone.this : key => {
      id                  = value.id
      name                = value.name
      resource_group_name = value.resource_group_name
    }
  }
}
