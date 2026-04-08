module "tags" {
  source              = "../../../../modules/platform-tags"
  environment         = var.environment
  application         = var.application
  created_by          = var.created_by
  business_owner      = var.business_owner
  source_repo         = var.source_repo
  terraform_workspace = var.terraform_workspace
  recovery_tier       = var.recovery_tier
  cost_center         = var.cost_center
  compliance_boundary = var.compliance_boundary
  creation_date_utc   = var.creation_date_utc
  last_modified_utc   = var.last_modified_utc
  additional_tags     = var.additional_tags
}

module "resource_group" {
  source   = "../../../../modules/resource_group"
  name     = var.resource_group_name
  location = var.location
  tags     = module.tags.tags
}

module "workspace" {
  source              = "../../../../modules/log-analytics"
  name                = var.workspace_name
  resource_group_name = module.resource_group.name
  location            = var.location
  retention_in_days   = var.workspace_retention_in_days
  tags                = module.tags.tags
}

#checkov:skip=CKV2_AZURE_33: Diagnostics archive private endpoints are managed separately from this management stack.
#checkov:skip=CKV2_AZURE_1: This shared diagnostics archive currently uses platform-managed keys rather than a dedicated CMK.
#checkov:skip=CKV2_AZURE_21: Blob monitoring is handled by Azure Monitor diagnostics outside Checkov's storage-insights graph.
module "diagnostics_archive" {
  source                        = "../../../../modules/storage"
  name                          = var.diagnostics_storage_account_name
  resource_group_name           = module.resource_group.name
  location                      = var.location
  public_network_access_enabled = false
  # shared_access_key_enabled must remain true here because
  # azurerm_log_analytics_storage_insights requires a storage key.
  # The storage insights resource is the only caller of primary_access_key;
  # all other access uses Azure AD RBAC. Track migration to a keyless
  # diagnostic export pattern (e.g. DCR-based export) when the provider
  # supports it without shared key.
  shared_access_key_enabled = true
  enable_network_rules      = true
  network_bypass            = ["AzureServices"]
  tags                      = module.tags.tags
}

resource "azurerm_log_analytics_storage_insights" "diagnostics_archive" {
  count                = var.enable_diagnostics_storage_insights ? 1 : 0
  name                 = "insights-diag-${var.environment}-${var.application}"
  resource_group_name  = module.resource_group.name
  workspace_id         = module.workspace.workspace_id
  storage_account_id   = module.diagnostics_archive.account_id
  storage_account_key  = module.diagnostics_archive.primary_access_key
  blob_container_names = length(module.diagnostics_archive.container_names) > 0 ? module.diagnostics_archive.container_names : ["*"]
  table_names          = ["*"]
}

module "action_group" {
  source              = "../../../../modules/action-group"
  name                = var.action_group_name
  resource_group_name = module.resource_group.name
  short_name          = var.action_group_short_name
  email_receivers     = var.action_group_email_receivers
  tags                = module.tags.tags
}

module "recovery_services_vault" {
  source              = "../../../../modules/recovery-services-vault"
  name                = var.recovery_services_vault_name
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = module.tags.tags
}

module "monitoring_baseline" {
  source                     = "../../../../modules/monitoring-baseline"
  name                       = "subscription-activity-logs"
  subscription_id            = var.subscription_id
  log_analytics_workspace_id = module.workspace.workspace_id
  storage_account_id         = module.diagnostics_archive.account_id
}

module "rsv_diagnostics" {
  source                     = "../../../../modules/diagnostics-1"
  name                       = "diag-rsv-${var.environment}-${var.application}"
  target_resource_id         = module.recovery_services_vault.id
  log_analytics_workspace_id = module.workspace.workspace_id
  enabled_logs               = ["AzureBackupReport", "AzureSiteRecoveryJobs", "AzureSiteRecoveryEvents"]
  enabled_metrics            = ["Health"]
}

resource "azurerm_management_lock" "resource_group" {
  name       = "lock-${var.resource_group_name}"
  scope      = module.resource_group.id
  lock_level = "CanNotDelete"
  notes      = "Management stack contains the central Log Analytics workspace and Recovery Services Vault. Accidental deletion would sever diagnostics for all platform and workload stacks."
}

# Microsoft Defender for Cloud plans
# Each resource enables a specific Defender plan for the subscription.
# For finserv, these plans are typically mandatory or heavily audited.
# Plans are scoped to the subscription configured in the root provider (var.subscription_id).
# Expand this list to cover every workload subscription once Defender licensing is confirmed.
locals {
  defender_plans = var.enable_defender ? toset([
    "AppServices",
    "KeyVaults",
    "SqlServers",
    "SqlServerVirtualMachines",
    "StorageAccounts",
    "Containers",
    "Arm",
  ]) : toset([])
}

resource "azurerm_security_center_subscription_pricing" "this" {
  for_each      = local.defender_plans
  resource_type = each.value
  tier          = "Standard"
}

resource "azurerm_security_center_workspace" "this" {
  count        = var.enable_defender ? 1 : 0
  scope        = "/subscriptions/${var.subscription_id}"
  workspace_id = module.workspace.workspace_id
}
