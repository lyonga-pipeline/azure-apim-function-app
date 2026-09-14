resource "azurerm_network_ddos_protection_plan" "plan" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
