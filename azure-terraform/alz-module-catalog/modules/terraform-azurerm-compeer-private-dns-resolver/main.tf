resource "azurerm_private_dns_resolver" "resolver" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  virtual_network_id  = var.virtual_network_id
  tags                = var.tags
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "inbound_endpoint" {
  for_each                = var.inbound_endpoints
  name                    = each.key
  private_dns_resolver_id = azurerm_private_dns_resolver.resolver.id
  location                = var.location
  tags                    = merge(var.tags, try(each.value.tags, {}))

  ip_configurations {
    private_ip_allocation_method = try(each.value.private_ip_allocation_method, "Dynamic")
    private_ip_address           = try(each.value.private_ip_address, null)
    subnet_id                    = each.value.subnet_id
  }
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "outbound_endpoint" {
  for_each                = var.outbound_endpoints
  name                    = each.key
  private_dns_resolver_id = azurerm_private_dns_resolver.resolver.id
  location                = var.location
  subnet_id               = each.value.subnet_id
  tags                    = merge(var.tags, try(each.value.tags, {}))
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "ruleset" {
  for_each                                   = var.forwarding_rulesets
  name                                       = each.key
  resource_group_name                        = var.resource_group_name
  location                                   = var.location
  private_dns_resolver_outbound_endpoint_ids = [for key in each.value.outbound_endpoint_keys : azurerm_private_dns_resolver_outbound_endpoint.outbound_endpoint[key].id]
  tags                                       = merge(var.tags, try(each.value.tags, {}))
}

resource "azurerm_private_dns_resolver_forwarding_rule" "forwarding_rule" {
  for_each                  = var.forwarding_rules
  name                      = each.key
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset[each.value.ruleset_key].id
  domain_name               = each.value.domain_name
  enabled                   = try(each.value.enabled, true)
  metadata                  = try(each.value.metadata, null)

  dynamic "target_dns_servers" {
    for_each = each.value.target_dns_servers
    content {
      ip_address = target_dns_servers.value.ip_address
      port       = try(target_dns_servers.value.port, 53)
    }
  }
}

resource "azurerm_private_dns_resolver_virtual_network_link" "vnet_link" {
  for_each                  = var.forwarding_ruleset_vnet_links
  name                      = each.key
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset[each.value.ruleset_key].id
  virtual_network_id        = each.value.virtual_network_id
  metadata                  = try(each.value.metadata, null)
}
