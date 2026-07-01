resource "azurerm_virtual_network_gateway_connection" "this" {
  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  type                       = var.type
  virtual_network_gateway_id = var.virtual_network_gateway_id
  express_route_circuit_id   = var.express_route_circuit_id
  authorization_key          = var.authorization_key
  routing_weight             = var.routing_weight
  tags                       = var.tags
}
