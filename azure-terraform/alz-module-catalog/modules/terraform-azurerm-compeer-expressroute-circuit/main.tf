resource "azurerm_express_route_circuit" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  service_provider_name    = var.service_provider_name
  peering_location         = var.peering_location
  bandwidth_in_mbps        = var.bandwidth_in_mbps
  allow_classic_operations = var.allow_classic_operations
  tags                     = var.tags

  sku {
    tier   = var.sku.tier
    family = var.sku.family
  }
}
