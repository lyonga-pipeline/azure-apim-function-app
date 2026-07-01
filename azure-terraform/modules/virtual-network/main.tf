resource "azurerm_virtual_network" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id == null ? [] : [var.ddos_protection_plan_id]
    content {
      id     = ddos_protection_plan.value
      enable = var.enable_ddos_protection_plan
    }
  }
}

resource "azurerm_subnet" "this" {
  for_each                                      = var.subnets
  name                                          = each.key
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.this.name
  address_prefixes                              = each.value.address_prefixes
  service_endpoints                             = try(each.value.service_endpoints, [])
  private_endpoint_network_policies             = try(each.value.private_endpoint_network_policies, "Enabled")
  private_link_service_network_policies_enabled = try(each.value.private_link_service_network_policies_enabled, true)

  dynamic "delegation" {
    for_each = try(each.value.delegations, {})
    content {
      name = delegation.key
      service_delegation {
        name    = delegation.value.name
        actions = try(delegation.value.actions, [])
      }
    }
  }
}
