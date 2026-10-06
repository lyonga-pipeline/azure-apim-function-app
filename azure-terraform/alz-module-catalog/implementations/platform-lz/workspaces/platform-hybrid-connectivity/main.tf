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

  connectivity_outputs      = try(data.tfe_outputs.connectivity[0].nonsensitive_values, {})
  connectivity_output_names = sort(keys(local.connectivity_outputs))

  connectivity_subnet_ids = try(
    local.connectivity_outputs.subnet_ids,
    try(local.connectivity_outputs.connectivity_hub_subnet_ids, {})
  )
  connectivity_subnet_id_keys = sort(try(keys(local.connectivity_subnet_ids), []))

  route_server_subnet_ids = {
    for key, cfg in try(var.hybrid_connectivity.route_servers, {}) : key => try(coalesce(
      try(cfg.subnet_id, null),
      try(var.route_server_subnet_ids[key], null),
      try(local.connectivity_subnet_ids[try(cfg.subnet_key, "RouteServerSubnet")], null),
      try(cfg.subnet_key, "RouteServerSubnet") == "RouteServerSubnet" ? try(local.connectivity_outputs.route_server_subnet_id, null) : null
    ), null)
  }

  route_server_resolution_errors = [
    for key, cfg in try(var.hybrid_connectivity.route_servers, {}) :
    format(
      "hybrid_connectivity.route_servers.%s requested subnet_key %q, but the connectivity workspace did not publish that subnet to this run. Connectivity workspace: %q. Published output names: [%s]. Published subnet_ids keys: [%s]. Re-run platform-connectivity with RouteServerSubnet and confirm TFE output-read access for this workspace, or set route_server_subnet_ids.%s / hybrid_connectivity.route_servers.%s.subnet_id explicitly.",
      key,
      try(cfg.subnet_key, "RouteServerSubnet"),
      var.connectivity_workspace_name,
      join(", ", local.connectivity_output_names),
      join(", ", local.connectivity_subnet_id_keys),
      key,
      key
    )
    if local.route_server_subnet_ids[key] == null
  ]

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
        subnet_id = local.route_server_subnet_ids[key]
      }
    )
  }

}

resource "terraform_data" "route_server_subnet_contract" {
  input = {
    connectivity_workspace_name = var.connectivity_workspace_name
    published_output_names      = local.connectivity_output_names
    published_subnet_id_keys    = local.connectivity_subnet_id_keys
    explicit_subnet_ids         = var.route_server_subnet_ids
    resolved_subnet_ids         = local.route_server_subnet_ids
    errors                      = local.route_server_resolution_errors
  }

  lifecycle {
    precondition {
      condition     = length(local.route_server_resolution_errors) == 0
      error_message = join("\n", local.route_server_resolution_errors)
    }
  }
}

module "hybrid_connectivity" {
  source = "../../../../patterns/terraform-azurerm-compeer-platform-hybrid-connectivity"
  count  = local.enabled ? 1 : 0

  depends_on = [terraform_data.route_server_subnet_contract]

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
