resource "azurerm_network_security_group" "network_security_group" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  dynamic "security_rule" {
    for_each = local.security_rules
    content {
      name                                       = security_rule.value.name
      description                                = lookup(security_rule.value, "description", null)
      protocol                                   = security_rule.value.protocol
      source_port_range                          = lookup(security_rule.value, "source_port_range", null)
      source_port_ranges                         = lookup(security_rule.value, "source_port_ranges", null)
      destination_port_range                     = lookup(security_rule.value, "destination_port_range", null)
      destination_port_ranges                    = lookup(security_rule.value, "destination_port_ranges", null)
      source_address_prefix                      = lookup(security_rule.value, "source_address_prefix", null)
      source_address_prefixes                    = lookup(security_rule.value, "source_address_prefixes", null)
      source_application_security_group_ids      = lookup(security_rule.value, "source_application_security_group_ids", null)
      destination_address_prefix                 = lookup(security_rule.value, "destination_address_prefix", null)
      destination_address_prefixes               = lookup(security_rule.value, "destination_address_prefixes", null)
      destination_application_security_group_ids = lookup(security_rule.value, "destination_application_security_group_ids", null)
      access                                     = security_rule.value.access
      priority                                   = security_rule.value.priority
      direction                                  = security_rule.value.direction
    }
  }
  tags = var.tags
}
