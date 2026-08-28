resource "azurerm_virtual_network" "this" {
  name                           = var.name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  address_space                  = var.address_space
  dns_servers                    = var.dns_servers
  bgp_community                  = var.bgp_community
  edge_zone                      = var.edge_zone
  flow_timeout_in_minutes        = var.flow_timeout_in_minutes
  private_endpoint_vnet_policies = var.private_endpoint_vnet_policies
  tags                           = var.tags

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id == null ? [] : [var.ddos_protection_plan_id]
    content {
      id     = ddos_protection_plan.value
      enable = var.enable_ddos_protection_plan
    }
  }

  dynamic "encryption" {
    for_each = var.encryption == null ? [] : [var.encryption]
    content {
      enforcement = encryption.value.enforcement
    }
  }

  dynamic "ip_address_pool" {
    for_each = var.ip_address_pools
    content {
      id                     = ip_address_pool.value.id
      number_of_ip_addresses = ip_address_pool.value.number_of_ip_addresses
    }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    read   = try(var.timeouts.read, null)
    delete = try(var.timeouts.delete, null)
  }
}

resource "azurerm_subnet" "this" {
  for_each                                      = var.subnets
  name                                          = each.key
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.this.name
  address_prefixes                              = each.value.address_prefixes
  service_endpoints                             = try(each.value.service_endpoints, [])
  service_endpoint_policy_ids                   = try(each.value.service_endpoint_policy_ids, [])
  default_outbound_access_enabled               = try(each.value.default_outbound_access_enabled, null)
  private_endpoint_network_policies             = try(each.value.private_endpoint_network_policies, "Enabled")
  private_link_service_network_policies_enabled = try(each.value.private_link_service_network_policies_enabled, true)
  sharing_scope                                 = try(each.value.sharing_scope, null)

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

  dynamic "ip_address_pool" {
    for_each = try(each.value.ip_address_pool, null) == null ? [] : [each.value.ip_address_pool]
    content {
      id                     = ip_address_pool.value.id
      number_of_ip_addresses = ip_address_pool.value.number_of_ip_addresses
    }
  }

  timeouts {
    create = try(each.value.timeouts.create, null)
    update = try(each.value.timeouts.update, null)
    read   = try(each.value.timeouts.read, null)
    delete = try(each.value.timeouts.delete, null)
  }
}
