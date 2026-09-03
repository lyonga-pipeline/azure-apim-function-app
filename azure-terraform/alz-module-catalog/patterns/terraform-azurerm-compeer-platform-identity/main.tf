data "azurerm_client_config" "current" {}

module "tags" {
  source = "../../modules/terraform-azurerm-compeer-platform-tags"

  environment           = var.environment
  application           = var.platform_tags.application
  owner                 = var.platform_tags.owner
  source_repo           = var.platform_tags.source_repo
  created_on            = var.platform_tags.created_on
  criticality_tier      = var.platform_tags.criticality_tier
  data_classification   = var.platform_tags.data_classification
  lifecycle_state       = var.platform_tags.lifecycle_state
  cost_center           = var.platform_tags.cost_center
  gl_category           = var.platform_tags.gl_category
  application_component = var.platform_tags.application_component
  modified_on           = var.platform_tags.modified_on
  created_by            = var.platform_tags.created_by
  dr_tier               = var.platform_tags.dr_tier
  expiration_date       = var.platform_tags.expiration_date
  additional_tags       = var.platform_tags.additional_tags
}

module "resource_group" {
  source = "../../modules/terraform-azurerm-compeer-resource-group"

  name     = var.resource_group.name
  location = var.location
  tags     = module.tags.tags
}

module "platform_identities" {
  source   = "../../modules/terraform-azurerm-compeer-user-assigned-identity"
  for_each = var.platform_identities

  name                = each.value.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.tags.tags
}

module "key_vault" {
  source = "../../modules/terraform-azurerm-compeer-keyvault"

  name                        = var.key_vault.name
  resource_group_name         = module.resource_group.name
  location                    = module.resource_group.location
  tenant_id                   = var.tenant_id
  sku_name                    = var.key_vault.sku_name
  soft_delete_retention_days  = var.key_vault.soft_delete_retention_days
  purge_protection_enabled    = var.key_vault.purge_protection_enabled
  rbac_authorization_enabled  = try(var.key_vault.rbac_authorization_enabled, true)
  access_policies             = try(var.key_vault.access_policies, [])
  access_policies_by_key      = try(var.key_vault.access_policies_by_key, {})
  enabled_for_deployment      = try(var.key_vault.enabled_for_deployment, false)
  enabled_for_disk_encryption = try(var.key_vault.enabled_for_disk_encryption, false)
  enabled_for_template_deployment = try(
    var.key_vault.enabled_for_template_deployment,
    false
  )
  public_network_access_enabled = try(var.key_vault.public_network_access_enabled, false)
  network_acls = coalesce(try(var.key_vault.network_acls, null), {
    bypass         = "None"
    default_action = "Deny"
  })
  contacts = values(var.key_vault.contacts)
  timeouts = try(var.key_vault.timeouts, {})
  tags     = module.tags.tags
}

locals {
  identity_role_assignments = {
    for key, assignment in var.identity_role_assignments : key => {
      scope                            = coalesce(try(assignment.scope, null), module.key_vault.id)
      name                             = try(assignment.name, null)
      principal_id                     = module.platform_identities[assignment.identity_key].principal_id
      principal_type                   = assignment.principal_type
      role_definition_name             = try(assignment.role_definition_name, null)
      role_definition_id               = try(assignment.role_definition_id, null)
      description                      = try(assignment.description, null)
      condition                        = try(assignment.condition, null)
      condition_version                = try(assignment.condition_version, null)
      skip_service_principal_aad_check = try(assignment.skip_service_principal_aad_check, null)
      delegated_managed_identity_resource_id = try(
        assignment.delegated_managed_identity_resource_id,
        null
      )
    }
  }
}

module "role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = merge(var.external_role_assignments, local.identity_role_assignments)
}

module "key_vault_private_endpoint" {
  source = "../../modules/terraform-azurerm-compeer-private-endpoint"
  count  = var.key_vault_private_endpoint == null ? 0 : 1

  name                = var.key_vault_private_endpoint.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  edge_zone           = try(var.key_vault_private_endpoint.edge_zone, null)
  subnet_id           = var.key_vault_private_endpoint.subnet_id
  private_service_connections = [
    {
      name                           = "${var.key_vault_private_endpoint.name}-psc"
      is_manual_connection           = false
      private_connection_resource_id = module.key_vault.id
      subresource_names              = ["vault"]
    }
  ]
  private_dns_zone_group = [{
    name                 = "${var.key_vault_private_endpoint.name}-dns"
    private_dns_zone_ids = var.key_vault_private_endpoint.private_dns_zone_ids
  }]
  timeouts = try(var.key_vault_private_endpoint.timeouts, {})
  tags     = module.tags.tags
}

module "key_vault_diagnostics" {
  source = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  count  = var.log_analytics_workspace_id == null ? 0 : 1

  name                           = "${var.key_vault.name}-diag"
  target_resource_id             = module.key_vault.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = try(var.diagnostics.log_analytics_destination_type, null)
  logs                           = var.diagnostics.logs
  metrics                        = var.diagnostics.metrics
}

locals {
  identity_scope_ids = merge(
    {
      resource_group = module.resource_group.id
      key_vault      = module.key_vault.id
    },
    {
      for key, value in module.platform_identities : "identity:${key}" => value.id
    },
    var.additional_lock_scopes
  )
}

resource "azurerm_management_lock" "this" {
  for_each = var.management_locks

  name       = each.value.name
  scope      = coalesce(try(each.value.scope, null), try(local.identity_scope_ids[each.value.scope_key], null))
  lock_level = each.value.lock_level
  notes      = try(each.value.notes, null)
}
