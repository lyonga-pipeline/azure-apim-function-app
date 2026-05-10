output "ids" {
  value = { for key, value in azurerm_private_dns_a_record.this : key => value.id }
}
