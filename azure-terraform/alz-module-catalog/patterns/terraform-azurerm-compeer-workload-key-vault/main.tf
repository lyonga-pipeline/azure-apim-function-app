resource "terraform_data" "tag_contract" {
  lifecycle {
    precondition {
      condition     = try(var.tags.environment == var.environment && var.tags.appcode == lower(var.appcode), false)
      error_message = "Vault environment/appcode tags must match the naming inputs; do not mislabel non-production vaults as production."
    }
  }
}

module "naming" {
  source                = "../../modules/terraform-azurerm-compeer-naming"
  scope                 = "workload"
  region                = var.location
  environment           = var.environment
  domain                = var.domain
  appcode               = var.appcode
  private_endpoint_keys = ["vault"]
}

module "vault" {
  source                          = "../../modules/terraform-azurerm-compeer-key-vault"
  name                            = coalesce(var.name, module.naming.key_vault)
  resource_group_name             = var.resource_group_name
  location                        = var.location
  tenant_id                       = var.tenant_id
  sku_name                        = var.sku_name
  rbac_authorization_enabled      = true
  public_network_access_enabled   = false
  soft_delete_retention_days      = 90
  purge_protection_enabled        = true
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  network_acls = {
    bypass         = "None"
    default_action = "Deny"
  }
  tags       = var.tags
  depends_on = [terraform_data.tag_contract]
}

module "private_endpoint" {
  source              = "../../modules/terraform-azurerm-compeer-private-endpoint"
  name                = module.naming.private_endpoint_names["vault"]
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id
  private_service_connections = [{
    name                           = module.naming.private_endpoint_names["vault"]
    is_manual_connection           = false
    private_connection_resource_id = module.vault.id
    subresource_names              = ["vault"]
  }]
  private_dns_zone_group = [{ name = "default", private_dns_zone_ids = [var.private_dns_zone_id] }]
  tags                   = var.tags
}

locals {
  role_assignments = merge(
    { for key, reader in var.secret_readers : "reader-${key}" => {
      scope                            = module.vault.id
      principal_id                     = reader.principal_id
      principal_type                   = reader.principal_type
      role_definition_name             = "Key Vault Secrets User"
      skip_service_principal_aad_check = reader.principal_type == "ServicePrincipal"
    } },
    { for key, id in var.secret_officer_group_ids : "officer-${key}" => {
      scope                = module.vault.id
      principal_id         = id
      principal_type       = "Group"
      role_definition_name = "Key Vault Secrets Officer"
    } }
  )
}

module "roles" {
  source      = "../../modules/terraform-azurerm-compeer-role-assignments"
  assignments = local.role_assignments
}

module "diagnostics" {
  source                     = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  name                       = "diag-${module.vault.name}-law"
  target_resource_id         = module.vault.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  logs                       = { audit = { category = "AuditEvent" } }
  metrics                    = { all = { category = "AllMetrics" } }
}
