data "tfe_outputs" "management" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.management_workspace_name
}

data "tfe_outputs" "connectivity" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.connectivity_workspace_name
}

data "tfe_outputs" "governance" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.governance_workspace_name
}

resource "time_static" "deployment_created" {}

locals {
  enabled = try(var.workload_spoke.enabled, false)

  # This workspace owns the deployment-lifecycle boundary for every resource
  # it creates, so it - not the tags module - owns created_on's stability.
  # time_static computes its value once, on first apply, and stores it in
  # state; every later plan reuses the same value instead of recomputing it
  # (unlike timestamp(), which would re-diff this tag on every single plan).
  # This intentionally supersedes any created_on set in workload_tags below.
  deployment_created_on = formatdate("YYYY-MM-DD", time_static.deployment_created.rfc3339)

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  connectivity_outputs = merge(
    try(data.tfe_outputs.connectivity[0].nonsensitive_values, {}),
    try(data.tfe_outputs.connectivity[0].values, {})
  )

  log_analytics_workspace_id = try(coalesce(var.log_analytics_workspace_id, try(local.management_outputs.log_analytics_workspace_id, null)), null)

  governance_outputs = merge(
    try(data.tfe_outputs.governance[0].nonsensitive_values, {}),
    try(data.tfe_outputs.governance[0].values, {})
  )

  # Platform_Output_Contracts_IAC-10: an application root needs the mandatory
  # tag keys but should never get a state-sharing grant on platform-governance
  # for the sake of one list - this workspace reads it once via tfe_outputs
  # and re-publishes it as spoke_mandatory_tag_keys (see outputs.tf).
  mandatory_tag_keys = try(local.governance_outputs.mandatory_tag_keys, [])

  hub_connection = try(var.workload_spoke.hub_connection, null) != null ? var.workload_spoke.hub_connection : (
    try(local.connectivity_outputs.hub_virtual_network_id, null) == null ? null : {
      hub_virtual_network_id  = local.connectivity_outputs.hub_virtual_network_id
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    }
  )

  generated_private_dns_zone_links = {
    for key in var.private_dns_zone_link_keys : key => {
      private_dns_zone_name = local.connectivity_outputs.private_dns_zone_names[key]
      resource_group_name   = local.connectivity_outputs.private_dns_zone_resource_group_names[key]
      registration_enabled  = false
    }
    if contains(keys(try(local.connectivity_outputs.private_dns_zone_names, {})), key)
  }

  private_dns_zone_links = length(try(var.workload_spoke.private_dns_zone_links, {})) > 0 ? var.workload_spoke.private_dns_zone_links : local.generated_private_dns_zone_links

  # name defaults to the naming module's <appcode>-<region>-<env>-vault when
  # workload_appcode is set - an explicit workload_key_vault.name in tfvars
  # always wins. try() around the whole coalesce: when NEITHER is set (no
  # appcode, no explicit name), coalesce(null, null) errors on its own -
  # this preserves the prior, correct behaviour of staying null so the
  # pattern's own "name is required when enabled" validation still fires,
  # rather than silently falling back to an empty string.
  workload_key_vault_name = try(coalesce(try(var.workload_spoke.workload_key_vault.name, null), local.std_names.workload_key_vault), null)

  workload_key_vault = (
    try(var.workload_spoke.workload_key_vault.enabled, false) &&
    local.log_analytics_workspace_id != null &&
    try(var.workload_spoke.workload_key_vault.diagnostics.log_analytics_workspace_id, null) == null
    ) ? merge(var.workload_spoke.workload_key_vault, {
      name = local.workload_key_vault_name
      diagnostics = merge(try(var.workload_spoke.workload_key_vault.diagnostics, {}), {
        log_analytics_workspace_id = local.log_analytics_workspace_id
      })
  }) : merge(try(var.workload_spoke.workload_key_vault, { enabled = false }), { name = local.workload_key_vault_name })
}

module "workload_spoke" {
  source = "../../../../patterns/terraform-azurerm-compeer-workload-spoke"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  location        = var.location
  environment     = var.environment
  # {appcode = var.workload_appcode} sits at the LOWEST merge priority - it's
  # a default, not an override, so an explicit workload_tags.appcode (or the
  # equivalent nested under workload_spoke.workload_tags/.platform_tags)
  # still wins. This keeps the tag and the naming module's own appcode-based
  # names (Key Vault, storage accounts) tracking the same one value instead
  # of two separately hand-maintained copies.
  workload_tags                   = merge({ appcode = var.workload_appcode }, var.workload_tags, try(var.workload_spoke.workload_tags, try(var.workload_spoke.platform_tags, {})), { created_on = local.deployment_created_on })
  resource_group                  = merge({ name = local.std_names.resource_group }, try(var.workload_spoke.resource_group, {}))
  spoke_vnet                      = merge({ name = local.std_names.spoke_vnet }, try(var.workload_spoke.spoke_vnet, {}))
  hub_connection                  = local.hub_connection
  private_dns_zone_links          = local.private_dns_zone_links
  workload_identity               = try(var.workload_spoke.workload_identity, { enabled = false })
  workload_key_vault              = local.workload_key_vault
  role_assignments                = try(var.workload_spoke.role_assignments, {})
  management_locks                = try(var.workload_spoke.management_locks, {})
  diagnostic_settings             = try(var.workload_spoke.diagnostic_settings, {})
  additional_scopes               = try(var.workload_spoke.additional_scopes, {})
  network_security_groups         = local.std_maps.network_security_groups
  subnet_nsg_associations         = try(var.workload_spoke.subnet_nsg_associations, {})
  route_tables                    = local.std_maps.route_tables
  subnet_route_table_associations = try(var.workload_spoke.subnet_route_table_associations, {})
  private_endpoints               = local.std_maps.private_endpoints
  workload_storage_accounts       = local.std_maps.workload_storage_accounts
}
