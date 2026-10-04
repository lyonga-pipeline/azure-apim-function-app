data "tfe_outputs" "connectivity" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.connectivity_workspace_name
}

resource "time_static" "deployment_created" {}

locals {
  enabled = try(var.hybrid_connectivity.enabled, false)

  # This workspace owns the deployment-lifecycle boundary for every resource
  # it creates, so it - not the tags module - owns created_on's stability.
  # time_static computes its value once, on first apply, and stores it in
  # state; every later plan reuses the same value instead of recomputing it
  # (unlike timestamp(), which would re-diff this tag on every single plan).
  # This intentionally supersedes any created_on set in platform_tags below.
  deployment_created_on = formatdate("YYYY-MM-DD", time_static.deployment_created.rfc3339)

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

  route_servers = {
    for key, cfg in try(var.hybrid_connectivity.route_servers, {}) : key => merge(
      cfg,
      {
        subnet_id = try(coalesce(
          try(cfg.subnet_id, null),
          try(local.connectivity_outputs.subnet_ids[try(cfg.subnet_key, "RouteServerSubnet")], null)
        ), null)
      }
    )
  }

}

module "hybrid_connectivity" {
  source = "../../../../patterns/terraform-azurerm-compeer-platform-hybrid-connectivity"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  location        = var.location
  environment     = var.environment
  platform_tags   = merge(var.platform_tags, try(var.hybrid_connectivity.platform_tags, {}), { created_on = local.deployment_created_on })
  naming = {
    region             = var.location
    environment        = var.environment
    storage_uniqueness = var.subscription_id
  }
  resource_group           = try(var.hybrid_connectivity.resource_group, {})
  expressroute_posture     = try(var.hybrid_connectivity.expressroute_posture, { enabled = false })
  expressroute_circuits    = try(var.hybrid_connectivity.expressroute_circuits, {})
  gateway_public_ips       = try(var.hybrid_connectivity.gateway_public_ips, try(var.hybrid_connectivity.expressroute_gateway_public_ips, {}))
  expressroute_gateway     = local.expressroute_gateway
  expressroute_connections = try(var.hybrid_connectivity.expressroute_connections, {})
  route_server_public_ips  = try(var.hybrid_connectivity.route_server_public_ips, {})
  route_servers            = local.route_servers
}
