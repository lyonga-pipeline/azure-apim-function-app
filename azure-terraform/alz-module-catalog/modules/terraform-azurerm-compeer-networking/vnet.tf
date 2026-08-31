# Virtual Network + subnets resource module.
#
# Ownership boundary: this module owns the VNet and its subnets only. Resource
# groups, DDoS protection plans, Network Watcher, NSGs, route tables, private DNS
# zones and peerings are owned by their dedicated modules and passed in by ID.

resource "azurerm_virtual_network" "vnet" {
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
      enable = true
    }
  }

  dynamic "encryption" {
    for_each = var.encryption == null ? [] : [var.encryption]
    content {
      enforcement = encryption.value.enforcement
    }
  }

  timeouts {
    create = try(var.timeouts.create, null)
    update = try(var.timeouts.update, null)
    read   = try(var.timeouts.read, null)
    delete = try(var.timeouts.delete, null)
  }
}

resource "azurerm_subnet" "subnet" {
  for_each = var.subnets

  name                                          = each.key
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = each.value.address_prefixes
  service_endpoints                             = each.value.service_endpoints
  service_endpoint_policy_ids                   = each.value.service_endpoint_policy_ids
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  default_outbound_access_enabled               = each.value.default_outbound_access_enabled

  dynamic "delegation" {
    for_each = each.value.delegations
    content {
      name = delegation.key
      service_delegation {
        name    = delegation.value.name
        actions = delegation.value.actions
      }
    }
  }
}
