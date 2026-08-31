output "ids" {
  value = { for key, value in azurerm_private_dns_a_record.this : key => value.id }
}

output "names" {
  description = "A-record names keyed by input key."
  value       = { for k, v in azurerm_private_dns_a_record.this : k => v.name }
}

output "fqdns" {
  description = "A-record FQDNs keyed by input key."
  value       = { for k, v in azurerm_private_dns_a_record.this : k => v.fqdn }
}
