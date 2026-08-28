output "ids" {
  value = { for key, value in azurerm_private_dns_zone_virtual_network_link.this : key => value.id }
}
output "names" {
  value = { for key, value in azurerm_private_dns_zone_virtual_network_link.this : key => value.name }
}
output "links" {
  value = {
    for key, value in azurerm_private_dns_zone_virtual_network_link.this : key => {
      id                    = value.id
      name                  = value.name
      resource_group_name   = value.resource_group_name
      private_dns_zone_name = value.private_dns_zone_name
      virtual_network_id    = value.virtual_network_id
      registration_enabled  = value.registration_enabled
    }
  }
}
