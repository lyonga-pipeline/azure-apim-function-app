data "azurerm_client_config" "current" {}

module "tags" {
  source = "../../../modules/platform-tags"

  environment         = var.environment
  application         = var.platform_tags.application
  business_owner      = var.platform_tags.business_owner
  source_repo         = var.platform_tags.source_repo
  terraform_workspace = var.platform_tags.terraform_workspace
  recovery_tier       = var.platform_tags.recovery_tier
  cost_center         = var.platform_tags.cost_center
  data_classification = var.platform_tags.data_classification
  compliance_boundary = var.platform_tags.compliance_boundary
  additional_tags     = var.platform_tags.additional_tags
}

module "resource_group" {
  source = "../../../modules/resource-group"

  name     = var.resource_group.name
  location = var.location
  tags     = module.tags.tags
}

module "platform_identities" {
  source   = "../../../modules/user-assigned-identity"
  for_each = var.platform_identities

  name                = each.value.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.tags.tags
}

module "key_vault" {
  source = "../../../modules/key-vault"

  name                          = var.key_vault.name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  tenant_id                     = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)
  sku_name                      = var.key_vault.sku_name
  soft_delete_retention_days    = var.key_vault.soft_delete_retention_days
  purge_protection_enabled      = var.key_vault.purge_protection_enabled
  enable_rbac_authorization     = true
  public_network_access_enabled = false
  network_acls = {
    bypass         = "None"
    default_action = "Deny"
  }
  contacts = var.key_vault.contacts
  tags     = module.tags.tags
}

locals {
  identity_role_assignments = {
    for key, assignment in var.identity_role_assignments : key => {
      scope                = coalesce(try(assignment.scope, null), module.key_vault.id)
      principal_id         = module.platform_identities[assignment.identity_key].principal_id
      principal_type       = assignment.principal_type
      role_definition_name = try(assignment.role_definition_name, null)
      role_definition_id   = try(assignment.role_definition_id, null)
      description          = try(assignment.description, null)
    }
  }
}

module "role_assignments" {
  source = "../../../modules/role-assignments"

  assignments = merge(var.external_role_assignments, local.identity_role_assignments)
}

module "key_vault_private_endpoint" {
  source = "../../../modules/private-endpoint"
  count  = var.key_vault_private_endpoint == null ? 0 : 1

  name                = var.key_vault_private_endpoint.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = var.key_vault_private_endpoint.subnet_id
  private_service_connection = {
    private_connection_resource_id = module.key_vault.id
    subresource_names              = ["vault"]
  }
  private_dns_zone_group = {
    private_dns_zone_ids = var.key_vault_private_endpoint.private_dns_zone_ids
  }
  tags = module.tags.tags
}

module "key_vault_diagnostics" {
  source = "../../../modules/diagnostic-settings"
  count  = var.log_analytics_workspace_id == null ? 0 : 1

  name                       = "${var.key_vault.name}-diag"
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  logs                       = var.diagnostics.logs
  metrics                    = var.diagnostics.metrics
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
