data "tfe_outputs" "connectivity" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.connectivity_workspace_name
}

locals {
  enabled = try(var.hybrid_connectivity.enabled, false)

  connectivity_outputs = merge(
    try(data.tfe_outputs.connectivity[0].nonsensitive_values, {}),
    try(data.tfe_outputs.connectivity[0].values, {})
  )

  expressroute_gateway = try(var.hybrid_connectivity.expressroute_gateway, null) == null ? null : merge(
    var.hybrid_connectivity.expressroute_gateway,
    {
      ip_configurations = {
        for key, cfg in try(var.hybrid_connectivity.expressroute_gateway.ip_configurations, {}) : key => merge(
          cfg,
          {
            gateway_subnet_id = coalesce(try(cfg.gateway_subnet_id, null), try(local.connectivity_outputs.subnet_ids["GatewaySubnet"], null))
          }
        )
      }
    }
  )

  vpn_gateway = try(var.hybrid_connectivity.vpn_gateway, null) == null ? null : merge(
    var.hybrid_connectivity.vpn_gateway,
    {
      ip_configurations = {
        for key, cfg in try(var.hybrid_connectivity.vpn_gateway.ip_configurations, {}) : key => merge(
          cfg,
          {
            gateway_subnet_id = coalesce(try(cfg.gateway_subnet_id, null), try(local.connectivity_outputs.subnet_ids["GatewaySubnet"], null))
          }
        )
      }
    }
  )
}

module "hybrid_connectivity" {
  source = "../../../../patterns/terraform-azurerm-compeer-platform-hybrid-connectivity"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id          = var.subscription_id
  location                 = var.location
  environment              = var.environment
  platform_tags            = merge(var.platform_tags, try(var.hybrid_connectivity.platform_tags, {}))
  resource_group           = merge({ name = local.std_names.resource_group }, try(var.hybrid_connectivity.resource_group, {}))
  expressroute_posture     = try(var.hybrid_connectivity.expressroute_posture, { enabled = false })
  expressroute_circuits    = try(var.hybrid_connectivity.expressroute_circuits, {})
  gateway_public_ips       = try(var.hybrid_connectivity.gateway_public_ips, try(var.hybrid_connectivity.expressroute_gateway_public_ips, {}))
  expressroute_gateway     = local.expressroute_gateway
  expressroute_connections = try(var.hybrid_connectivity.expressroute_connections, {})
  vpn_posture              = try(var.hybrid_connectivity.vpn_posture, { enabled = false })
  vpn_gateway_public_ips   = try(var.hybrid_connectivity.vpn_gateway_public_ips, {})
  vpn_gateway              = local.vpn_gateway
  local_network_gateways   = try(var.hybrid_connectivity.local_network_gateways, {})
  vpn_connections          = try(var.hybrid_connectivity.vpn_connections, {})
}
