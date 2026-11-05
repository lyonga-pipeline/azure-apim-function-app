resource "azurerm_network_security_group" "network_security_group" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  # Explicit [] removes the last inline rule; an omitted dynamic block leaves old rules unmanaged.
  security_rule = [for rule in values(local.security_rules) : rule]
  tags          = var.tags
}
