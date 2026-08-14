output "ids" {
  value = { for key, value in azurerm_private_dns_zone.this : key => value.id }
}
output "names" {
  value = { for key, value in azurerm_private_dns_zone.this : key => value.name }
}
