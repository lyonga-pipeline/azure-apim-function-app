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

locals {
  enabled = try(var.identity.enabled, false)

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  connectivity_outputs = merge(
    try(data.tfe_outputs.connectivity[0].nonsensitive_values, {}),
    try(data.tfe_outputs.connectivity[0].values, {})
  )

  log_analytics_workspace_id = coalesce(var.log_analytics_workspace_id, try(local.management_outputs.log_analytics_workspace_id, null))

  key_vault_private_endpoint_from_connectivity_enabled = try(var.identity.key_vault_private_endpoint_from_connectivity.enabled, false)
  key_vault_private_endpoint_from_connectivity = local.key_vault_private_endpoint_from_connectivity_enabled ? {
    name                 = try(var.identity.key_vault_private_endpoint_from_connectivity.name, "${var.environment}-platform-kv-pe")
    subnet_id            = coalesce(try(var.identity.key_vault_private_endpoint_from_connectivity.subnet_id, null), try(local.connectivity_outputs.subnet_ids["private_endpoints"], null))
    private_dns_zone_ids = compact(concat(try(var.identity.key_vault_private_endpoint_from_connectivity.private_dns_zone_ids, []), [try(local.connectivity_outputs.private_dns_zone_ids["key_vault"], null)]))
  } : null

  key_vault_private_endpoint = try(var.identity.key_vault_private_endpoint, null) != null ? var.identity.key_vault_private_endpoint : local.key_vault_private_endpoint_from_connectivity
}

module "identity" {
  source = "../../../../patterns/terraform-azurerm-compeer-platform-identity"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id            = var.subscription_id
  tenant_id                  = var.tenant_id
  location                   = var.location
  environment                = var.environment
  platform_tags              = merge(var.platform_tags, try(var.identity.platform_tags, {}))
  resource_group             = try(var.identity.resource_group, null)
  platform_identities        = try(var.identity.platform_identities, {})
  key_vault                  = try(var.identity.key_vault, null)
  key_vault_private_endpoint = local.key_vault_private_endpoint
  log_analytics_workspace_id = local.log_analytics_workspace_id
  diagnostics                = try(var.identity.diagnostics, null)
  identity_role_assignments  = try(var.identity.identity_role_assignments, {})
  external_role_assignments  = try(var.identity.external_role_assignments, {})
  management_locks           = try(var.identity.management_locks, {})
  additional_lock_scopes     = try(var.identity.additional_lock_scopes, {})
}
