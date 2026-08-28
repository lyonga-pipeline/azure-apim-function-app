output "ids" {
  description = "Local network gateway IDs keyed by input key."
  value       = { for key, gateway in azurerm_local_network_gateway.this : key => gateway.id }
}

output "names" {
  description = "Local network gateway names keyed by input key."
  value       = { for key, gateway in azurerm_local_network_gateway.this : key => gateway.name }
}

output "gateway_addresses" {
  description = "Local network gateway public addresses keyed by input key."
  value       = { for key, gateway in azurerm_local_network_gateway.this : key => gateway.gateway_address }
}

output "gateways" {
  description = "Local network gateway attributes keyed by input key for downstream composition."
  value = {
    for key, gateway in azurerm_local_network_gateway.this : key => {
      id                  = gateway.id
      name                = gateway.name
      resource_group_name = gateway.resource_group_name
      location            = gateway.location
      gateway_address     = gateway.gateway_address
      address_space       = gateway.address_space
    }
  }
}
