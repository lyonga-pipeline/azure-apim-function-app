output "ids" {
  value = { for key, value in azurerm_private_dns_zone_virtual_network_link.this : key => value.id }
}
