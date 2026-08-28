output "ids" {
  value = { for key, value in azurerm_private_dns_zone.this : key => value.id }
}
output "names" {
  value = { for key, value in azurerm_private_dns_zone.this : key => value.name }
}
output "resource_group_names" {
  value = { for key, value in azurerm_private_dns_zone.this : key => value.resource_group_name }
}
output "zones" {
  value = {
    for key, value in azurerm_private_dns_zone.this : key => {
      id                  = value.id
      name                = value.name
      resource_group_name = value.resource_group_name
    }
  }
}
