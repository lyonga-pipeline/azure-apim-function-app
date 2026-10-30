# PHASE2 NEW: dedicated monitoring-only destination, never a workload data account.
module "storage" {
  for_each                 = local.archive
  source                   = "../../modules/terraform-azurerm-compeer-storage-account"
  name                     = each.value.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_replication_type = each.value.replication_type
  # Selected-network endpoint is required for Azure Monitor's trusted-service bypass.
  # No IP/VNet allow rules, anonymous access or shared keys; private endpoint for readers.
  public_network_access_enabled        = true
  trusted_service_only_access_approved = each.value.export_access_approved
  shared_access_key_enabled            = false
  default_to_oauth_authentication      = true
  allow_nested_items_to_be_public      = false
  infrastructure_encryption_enabled    = true
  min_tls_version                      = "TLS1_2"
  # Account-level WORM requires blob versioning; leave application-data change feed out of a log archive.
  blob_properties = { versioning_enabled = true, change_feed_enabled = false }
  immutability_policy = {
    allow_protected_append_writes = true
    period_since_creation_in_days = each.value.retention_days
    state                         = each.value.lock_immutability ? "Locked" : "Unlocked"
  }
  # Azure Monitor export needs trusted-service ingress; the private endpoint is for readers.
  # export_access_approved is acceptance evidence, not a claim that a private endpoint enables export.
  network_rules = { default_action = "Deny", bypass = ["AzureServices"] }
  tags          = var.tags
}
module "private_endpoint" {
  for_each            = local.archive
  source              = "../../modules/terraform-azurerm-compeer-private-endpoint"
  name                = "${each.value.name}-blob-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = each.value.private_endpoint_subnet_id
  private_service_connections = [{
    name                           = "archive-blob"
    private_connection_resource_id = module.storage[each.key].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }]
  private_dns_zone_group = [{ name = "central", private_dns_zone_ids = [each.value.private_dns_zone_id] }]
  tags                   = var.tags
}
# Account-level WORM applies to containers created by the LAW exporter (am-<table>).
# Container-policy resources cannot pre-create mixed-case am-<TableName> names safely.
# The established storage helper supports the account-level immutable policy interface.
resource "azurerm_log_analytics_data_export_rule" "archive" {
  for_each                = local.archive
  name                    = "phase2-regulatory-archive"
  resource_group_name     = try(split("/", each.value.workspace_id)[4], "")
  workspace_resource_id   = each.value.workspace_id
  destination_resource_id = module.storage[each.key].id
  table_names             = each.value.tables
  enabled                 = true
  depends_on              = [module.private_endpoint]
  lifecycle {
    precondition {
      condition     = lower(each.value.workspace_region) == lower(var.location)
      error_message = "Log Analytics export and its storage destination must be in the same Azure region."
    }
  }
}
module "lifecycle" {
  for_each           = { for key, value in local.archive : key => value if value.delete_after_days != null }
  source             = "../../modules/terraform-azurerm-compeer-storage-management-policy"
  storage_account_id = module.storage[each.key].id
  # LAW exports append blobs: lifecycle supports deletion, not cool-tier transitions.
  # WORM retention takes precedence; no destructive lifecycle rule without approval.
  rules = each.value.delete_after_days == null ? {} : {
    archive-retention = {
      enabled = true
      filters = { blob_types = ["appendBlob"] }
      actions = { base_blob = {
        delete_after_days_since_modification_greater_than = each.value.delete_after_days
      } }
    }
  }
}

# Audit the archive too; same-LAW reuse is allowed only when its own audit tables are not exported.
module "audit" {
  for_each                       = local.archive
  source                         = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  name                           = "archive-blob-audit"
  target_resource_id             = "${module.storage[each.key].id}/blobServices/default"
  log_analytics_workspace_id     = each.value.audit_workspace_id
  log_analytics_destination_type = "Dedicated"
  logs                           = { for category in ["StorageRead", "StorageWrite", "StorageDelete"] : category => { category = category } }
}

module "account_metrics" {
  for_each                   = local.archive
  source                     = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  name                       = "archive-account-metrics"
  target_resource_id         = module.storage[each.key].id
  log_analytics_workspace_id = each.value.audit_workspace_id
  metrics                    = { all = { category = "AllMetrics" } }
}
