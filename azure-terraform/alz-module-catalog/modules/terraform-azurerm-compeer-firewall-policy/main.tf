resource "azurerm_firewall_policy" "policy" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = var.sku
  threat_intelligence_mode = var.threat_intelligence_mode
  tags                     = var.tags
}
