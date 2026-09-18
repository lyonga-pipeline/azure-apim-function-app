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

  # Resolve vpn_certificate_key_vault.private_endpoint.subnet_key -> the real
  # connectivity workspace's subnet_id, same pattern as the gateway subnets
  # above (network engineer request: reference the existing hub VNet/subnets
  # rather than a hand-copied ID). Only name/subnet_id/private_dns_zone_ids
  # are passed to the pattern - it has no subnet_key field of its own.
  vckv_pe = try(var.hybrid_connectivity.vpn_certificate_key_vault.private_endpoint, null)

  vpn_certificate_key_vault = try(var.hybrid_connectivity.vpn_certificate_key_vault, null) == null ? {} : merge(
    var.hybrid_connectivity.vpn_certificate_key_vault,
    local.vckv_pe == null ? {} : {
      private_endpoint = {
        name = local.vckv_pe.name
        subnet_id = coalesce(
          try(local.vckv_pe.subnet_id, null),
          try(local.connectivity_outputs.subnet_ids[local.vckv_pe.subnet_key], null)
        )
        private_dns_zone_ids = try(local.vckv_pe.private_dns_zone_ids, [])
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
  resource_group            = try(var.hybrid_connectivity.resource_group, {})
  expressroute_posture      = try(var.hybrid_connectivity.expressroute_posture, { enabled = false })
  expressroute_circuits     = try(var.hybrid_connectivity.expressroute_circuits, {})
  gateway_public_ips        = try(var.hybrid_connectivity.gateway_public_ips, try(var.hybrid_connectivity.expressroute_gateway_public_ips, {}))
  expressroute_gateway      = local.expressroute_gateway
  expressroute_connections  = try(var.hybrid_connectivity.expressroute_connections, {})
  vpn_posture               = try(var.hybrid_connectivity.vpn_posture, { enabled = false })
  vpn_gateway_public_ips    = try(var.hybrid_connectivity.vpn_gateway_public_ips, {})
  vpn_gateway               = local.vpn_gateway
  local_network_gateways    = try(var.hybrid_connectivity.local_network_gateways, {})
  vpn_connections           = try(var.hybrid_connectivity.vpn_connections, {})
  vpn_certificate_key_vault = local.vpn_certificate_key_vault
  vpn_certificate_identity  = try(var.hybrid_connectivity.vpn_certificate_identity, {})
}
