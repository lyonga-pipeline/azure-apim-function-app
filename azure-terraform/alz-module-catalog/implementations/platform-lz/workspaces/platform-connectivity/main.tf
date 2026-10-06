data "tfe_outputs" "management" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.management_workspace_name
}

# 23 Sep 2026 placement decision: domain controllers moved off the hub into a
# dedicated identity VNet, peered to the hub - this reads that VNet's ID back
# to create the hub-side half of the peering. Optional the same way
# management_outputs is: this workspace's own first apply (and every apply
# before directory-services has run at least once) simply gets no "identity"
# entry in additional_vnet_peerings below, not an error.
data "tfe_outputs" "directory_services" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.directory_services_workspace_name
}

resource "time_static" "deployment_created" {}

locals {
  enabled = try(var.connectivity.enabled, false)

  # This workspace owns the deployment-lifecycle boundary for every resource
  # it creates, so it - not the tags module - owns created_on's stability.
  # time_static computes its value once, on first apply, and stores it in
  # state; every later plan reuses the same value instead of recomputing it
  # (unlike timestamp(), which would re-diff this tag on every single plan).
  # This intentionally supersedes any created_on set in platform_tags below.
  deployment_created_on = formatdate("YYYY-MM-DD", time_static.deployment_created.rfc3339)

  required_resource_provider_namespaces = local.enabled ? toset([
    "Microsoft.Insights",
    "Microsoft.Network",
  ]) : toset([])

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  directory_services_outputs = merge(
    try(data.tfe_outputs.directory_services[0].nonsensitive_values, {}),
    try(data.tfe_outputs.directory_services[0].values, {})
  )

  log_analytics_workspace_id = try(coalesce(var.log_analytics_workspace_id, try(local.management_outputs.log_analytics_workspace_id, null)), null)

  # No "identity" entry at all until directory-services has published a real
  # VNet ID - merge() with an explicit tfvars override still wins/extends.
  additional_vnet_peerings = merge(
    try(local.directory_services_outputs.identity_vnet_id, null) == null ? {} : {
      identity = { remote_virtual_network_id = local.directory_services_outputs.identity_vnet_id }
    },
    try(var.connectivity.additional_vnet_peerings, {})
  )

  # Bastion: attach LAW diagnostics automatically when enabled. Name comes from
  # the pattern's naming module.
  bastion = merge(
    try(var.connectivity.bastion, { enabled = false }),
    (
      try(var.connectivity.bastion.enabled, false) &&
      local.log_analytics_workspace_id != null &&
      length(try(var.connectivity.bastion.diagnostic_settings, {})) == 0
      ) ? {
      diagnostic_settings = {
        law = {
          log_analytics_workspace_id = local.log_analytics_workspace_id
        }
      }
    } : {}
  )
}

resource "azurerm_resource_provider_registration" "required" {
  for_each = local.required_resource_provider_namespaces

  name = each.key

  lifecycle {
    prevent_destroy = true
  }
}

module "connectivity" {
  source = "../../../../patterns/terraform-azurerm-compeer-platform-connectivity"
  count  = local.enabled ? 1 : 0

  depends_on = [azurerm_resource_provider_registration.required]

  providers = {
    azurerm = azurerm
  }

  # Resource names come from the naming module inside the pattern (component =
  # "connectivity"). Add a `name` to a block in terraform.tfvars to override one.
  naming = {
    region             = var.location
    environment        = var.environment
    storage_uniqueness = var.subscription_id
  }

  subscription_id                 = var.subscription_id
  location                        = var.location
  environment                     = var.environment
  platform_tags                   = merge(var.platform_tags, try(var.connectivity.platform_tags, {}), { created_on = local.deployment_created_on })
  resource_group                  = try(var.connectivity.resource_group, {})
  hub_vnet                        = try(var.connectivity.hub_vnet, {})
  additional_vnet_peerings        = local.additional_vnet_peerings
  ddos_protection_plan            = try(var.connectivity.ddos_protection_plan, { enabled = false })
  palo_alto                       = try(var.connectivity.palo_alto, { enabled = false })
  dns_resolution                  = try(var.connectivity.dns_resolution, { enabled = false })
  bastion                         = local.bastion
  network_security_groups         = try(var.connectivity.network_security_groups, {})
  subnet_nsg_associations         = try(var.connectivity.subnet_nsg_associations, {})
  route_tables                    = try(var.connectivity.route_tables, {})
  subnet_route_table_associations = try(var.connectivity.subnet_route_table_associations, {})
  load_balancers                  = try(var.connectivity.load_balancers, {})
  network_watchers                = try(var.connectivity.network_watchers, {})
  network_watcher_flow_logs       = try(var.connectivity.network_watcher_flow_logs, {})
  private_dns_zones               = try(var.connectivity.private_dns_zones, {})
  privatelink_zone_catalogue      = try(var.connectivity.privatelink_zone_catalogue, [])
  privatelink_zone_region         = try(var.connectivity.privatelink_zone_region, var.location)
  role_assignments                = try(var.connectivity.role_assignments, {})
  management_locks                = try(var.connectivity.management_locks, {})
  diagnostic_settings             = try(var.connectivity.diagnostic_settings, {})
  additional_scopes               = try(var.connectivity.additional_scopes, {})
}
