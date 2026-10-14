data "azurerm_client_config" "hub" { provider = azurerm.hub }
data "azurerm_client_config" "spoke" { provider = azurerm.spoke }
data "azurerm_client_config" "dns" { provider = azurerm.dns }

resource "terraform_data" "contract" {
  lifecycle {
    precondition {
      condition = (
        can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", var.hub_virtual_network_id)) &&
        can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", var.spoke_virtual_network_id)) &&
        try(lower(var.hub_virtual_network_id) != lower(var.spoke_virtual_network_id), false) &&
        try(lower(split("/", var.hub_virtual_network_id)[2]) == lower(var.hub_subscription_id), false) &&
        try(lower(split("/", var.spoke_virtual_network_id)[2]) == lower(var.spoke_subscription_id), false)
      )
      error_message = "Supply two distinct full VNet IDs matching the approved hub/spoke subscriptions."
    }
    precondition {
      condition = (
        data.azurerm_client_config.hub.subscription_id == var.hub_subscription_id &&
        data.azurerm_client_config.spoke.subscription_id == var.spoke_subscription_id &&
        data.azurerm_client_config.hub.tenant_id == data.azurerm_client_config.spoke.tenant_id &&
        (var.tenant_id == null || var.tenant_id == "" || data.azurerm_client_config.hub.tenant_id == var.tenant_id) &&
        (length(var.private_dns_zones) == 0 || (
          data.azurerm_client_config.dns.subscription_id == coalesce(var.private_dns_subscription_id, var.hub_subscription_id) &&
          data.azurerm_client_config.dns.tenant_id == data.azurerm_client_config.hub.tenant_id
        ))
      )
      error_message = "Providers must match the approved hub, spoke and actual DNS subscriptions in one tenant. Cross-tenant peering requires a separately reviewed authorization pattern."
    }
    precondition {
      condition     = !var.hub_to_spoke.use_remote_gateways && !var.spoke_to_hub.allow_gateway_transit && var.hub_to_spoke.allow_gateway_transit == var.spoke_to_hub.use_remote_gateways
      error_message = "Only the hub may offer gateway transit, paired with the spoke using it. Enable after approved gateway/Route Server readiness."
    }
    precondition {
      condition = alltrue([for zone in values(var.private_dns_zones) :
        try(length(trimspace(zone.resource_group_name)) > 0, false) && (!startswith(lower(zone.name), "privatelink.") || !zone.registration_enabled)
      ])
      error_message = "Every DNS link needs the actual existing zone RG; Private Link service zones must not enable VM auto-registration."
    }
  }
}

module "hub_to_spoke_peering" {
  source                       = "../../modules/terraform-azurerm-compeer-vnet-peering"
  providers                    = { azurerm = azurerm.hub }
  peering_name                 = coalesce(var.peering_names.hub_to_spoke, "peer-${var.peering_name_prefix}-hub-to-spoke")
  rg_name                      = try(split("/", var.hub_virtual_network_id)[4], "")
  vnet_name                    = try(split("/", var.hub_virtual_network_id)[8], "")
  remote_virtual_network_id    = var.spoke_virtual_network_id
  allow_virtual_network_access = var.hub_to_spoke.allow_virtual_network_access
  allow_forwarded_traffic      = var.hub_to_spoke.allow_forwarded_traffic
  allow_gateway_transit        = var.hub_to_spoke.allow_gateway_transit
  use_remote_gateways          = var.hub_to_spoke.use_remote_gateways
  depends_on                   = [terraform_data.contract]
}

module "spoke_to_hub_peering" {
  source                       = "../../modules/terraform-azurerm-compeer-vnet-peering"
  providers                    = { azurerm = azurerm.spoke }
  peering_name                 = coalesce(var.peering_names.spoke_to_hub, "peer-${var.peering_name_prefix}-spoke-to-hub")
  rg_name                      = try(split("/", var.spoke_virtual_network_id)[4], "")
  vnet_name                    = try(split("/", var.spoke_virtual_network_id)[8], "")
  remote_virtual_network_id    = var.hub_virtual_network_id
  allow_virtual_network_access = var.spoke_to_hub.allow_virtual_network_access
  allow_forwarded_traffic      = var.spoke_to_hub.allow_forwarded_traffic
  allow_gateway_transit        = var.spoke_to_hub.allow_gateway_transit
  use_remote_gateways          = var.spoke_to_hub.use_remote_gateways
  # Azure checks the remote gateway-transit permission before enabling its use.
  depends_on = [module.hub_to_spoke_peering]
}

module "private_dns_spoke_links" {
  source    = "../../modules/terraform-azurerm-compeer-private-dns-vnet-link"
  providers = { azurerm = azurerm.dns }
  links = { for key, zone in var.private_dns_zones : key => {
    name                  = coalesce(zone.link_name, "lnk-${key}-${var.peering_name_prefix}-spoke")
    resource_group_name   = zone.resource_group_name
    private_dns_zone_name = zone.name
    virtual_network_id    = var.spoke_virtual_network_id
    registration_enabled  = zone.registration_enabled
    tags                  = var.tags
  } }
  tags       = var.tags
  depends_on = [module.spoke_to_hub_peering]
}
