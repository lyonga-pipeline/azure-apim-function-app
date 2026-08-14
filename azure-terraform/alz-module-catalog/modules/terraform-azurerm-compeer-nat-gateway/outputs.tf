output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = azurerm_nat_gateway.nat-gateway.id
}

output "public_ip_ids" {
  description = "The IDs of the public IPs associated with the NAT Gateway"
  value       = azurerm_public_ip.pip[*].id
}
