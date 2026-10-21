module "naming" {
  source                      = "../../modules/terraform-azurerm-compeer-naming"
  scope                       = "workload"
  region                      = var.location
  environment                 = var.environment
  domain                      = var.domain
  appcode                     = var.appcode
  resource_group_keys         = values(local.resource_group_purposes)
  storage_account_keys        = keys(local.enabled_storage_accounts)
  storage_uniqueness          = var.subscription_id
  subnet_keys                 = keys(var.subnets)
  nsg_keys                    = keys(var.subnets)
  route_table_keys            = keys(var.subnets)
  user_assigned_identity_keys = ["workload"]
}

module "tags" {
  source                = "../../modules/terraform-azurerm-compeer-platform-tags"
  environment           = var.environment
  appcode               = var.appcode
  application           = var.workload_tags.application
  owner                 = var.workload_tags.owner
  source_repo           = var.workload_tags.source_repo
  created_on            = var.workload_tags.created_on
  criticality_tier      = var.workload_tags.criticality_tier
  data_classification   = var.workload_tags.data_classification
  lifecycle_state       = var.workload_tags.lifecycle_state
  cost_center           = var.workload_tags.cost_center
  gl_category           = var.workload_tags.gl_category
  dr_tier               = var.workload_tags.dr_tier
  application_component = var.workload_tags.application_component
  modified_on           = var.workload_tags.modified_on
  additional_tags       = var.workload_tags.additional_tags
}

module "resource_groups" {
  source = "../../modules/terraform-azurerm-compeer-resource-group"
  resource_groups = { for key in local.resource_group_keys : key => {
    name     = local.resource_group_names[local.resource_group_purposes[key]]
    location = var.location
    tags     = module.tags.tags
  } }
  depends_on = [terraform_data.contracts]
}

module "network" {
  source                  = "../../modules/terraform-azurerm-compeer-virtual-network"
  name                    = module.naming.workload_vnet
  resource_group_name     = module.resource_groups.group_names["network"]
  location                = var.location
  address_space           = var.address_space
  dns_servers             = var.platform.dns_server_ips
  ddos_protection_plan_id = var.platform.ddos_protection_plan_id
  subnets                 = local.network_subnets
  tags                    = module.tags.tags
}


module "network_security_groups" {
  source              = "../../modules/terraform-azurerm-compeer-network-security-group"
  for_each            = var.subnets
  name                = module.naming.nsg_names[each.key]
  resource_group_name = module.resource_groups.group_names["network"]
  location            = var.location
  security_rules      = local.nsg_rules[each.key]
  tags                = module.tags.tags
}

module "nsg_associations" {
  source                    = "../../modules/terraform-azurerm-compeer-nsg-subnet-association"
  for_each                  = var.subnets
  subnet_id                 = local.subnet_ids[each.key]
  network_security_group_id = module.network_security_groups[each.key].id
}

module "route_tables" {
  source                        = "../../modules/terraform-azurerm-compeer-route-table"
  for_each                      = var.subnets
  name                          = module.naming.route_table_names[each.key]
  resource_group_name           = module.resource_groups.group_names["network"]
  location                      = var.location
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  routes                        = local.routes[each.key]
  tags                          = module.tags.tags
}

module "route_associations" {
  source         = "../../modules/terraform-azurerm-compeer-subnet-route-table-association"
  for_each       = var.subnets
  subnet_id      = local.subnet_ids[each.key]
  route_table_id = module.route_tables[each.key].id
}

module "workload_identity" {
  source              = "../../modules/terraform-azurerm-compeer-user-assigned-identity"
  name                = module.naming.user_assigned_identity_names["workload"]
  resource_group_name = module.resource_groups.group_names["security"]
  location            = var.location
  tags                = module.tags.tags
}

module "key_vault" {
  count                      = var.key_vault.enabled ? 1 : 0
  source                     = "../terraform-azurerm-compeer-workload-key-vault"
  resource_group_name        = module.resource_groups.group_names["security"]
  location                   = var.location
  tenant_id                  = var.tenant_id
  environment                = var.environment
  appcode                    = var.appcode
  domain                     = var.domain
  name                       = var.key_vault.name
  sku_name                   = var.key_vault.sku_name
  private_endpoint_subnet_id = local.subnet_ids["private_endpoints"]
  private_dns_zone_id        = var.platform.key_vault_private_dns_zone_id
  log_analytics_workspace_id = var.platform.log_analytics_workspace_id
  diagnostics = {
    enabled          = var.diagnostics.enabled
    existing_setting = lookup(var.diagnostics.existing_settings, "key_vault", null)
  }
  secret_readers = merge(var.key_vault.secret_readers, {
    workload = { principal_id = module.workload_identity.principal_id, principal_type = "ServicePrincipal" }
  })
  secret_officer_group_ids = var.key_vault.secret_officer_group_ids
  tags                     = module.tags.tags
  depends_on               = [module.nsg_associations, module.route_associations]
}

module "workload_access" {
  source      = "../../modules/terraform-azurerm-compeer-role-assignments"
  assignments = local.workload_access_assignments
}

module "storage" {
  source                            = "../../modules/terraform-azurerm-compeer-storage-account"
  for_each                          = local.storage_settings
  name                              = each.value.name
  resource_group_name               = module.resource_groups.group_names["data"]
  location                          = var.location
  account_replication_type          = each.value.account_replication_type
  min_tls_version                   = each.value.min_tls_version
  https_traffic_only_enabled        = each.value.https_traffic_only_enabled
  public_network_access_enabled     = each.value.public_network_access_enabled
  allow_nested_items_to_be_public   = each.value.allow_nested_items_to_be_public
  shared_access_key_enabled         = each.value.shared_access_key_enabled
  default_to_oauth_authentication   = each.value.default_to_oauth_authentication
  infrastructure_encryption_enabled = each.value.infrastructure_encryption_enabled
  cross_tenant_replication_enabled  = each.value.cross_tenant_replication_enabled
  network_rules                     = each.value.network_rules
  blob_properties                   = each.value.blob_properties
  tags                              = module.tags.tags
  depends_on                        = [terraform_data.capability_contract]
}

module "storage_endpoints" {
  source              = "../../modules/terraform-azurerm-compeer-private-endpoint"
  for_each            = local.enabled_storage_accounts
  name                = "${local.workload_stem}-${each.key}-blob-pe"
  resource_group_name = module.resource_groups.group_names["data"]
  location            = var.location
  subnet_id           = local.subnet_ids["private_endpoints"]
  private_service_connections = [{
    name                           = "${each.key}-blob"
    is_manual_connection           = false
    private_connection_resource_id = module.storage[each.key].id
    subresource_names              = ["blob"]
  }]
  private_dns_zone_group = [{ name = "default", private_dns_zone_ids = [var.platform.storage_blob_private_dns_zone_id] }]
  tags                   = module.tags.tags
  depends_on             = [module.nsg_associations, module.route_associations]
}

module "storage_access" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"
  assignments = { for key, account in local.enabled_storage_accounts : key => {
    scope                            = module.storage[key].id
    principal_id                     = module.workload_identity.principal_id
    principal_type                   = "ServicePrincipal"
    role_definition_name             = "Storage Blob Data Contributor"
    skip_service_principal_aad_check = true
  } if account.grant_workload_blob_access }
}

module "storage_metrics" {
  source                     = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  for_each                   = { for key, account in local.enabled_storage_accounts : key => account if var.diagnostics.enabled && !contains(keys(var.diagnostics.existing_settings), "storage.${key}.account") }
  name                       = "diag-${module.storage[each.key].name}-law"
  target_resource_id         = module.storage[each.key].id
  log_analytics_workspace_id = var.platform.log_analytics_workspace_id
  metrics                    = { all = { category = "AllMetrics" } }
  depends_on                 = [terraform_data.reuse_contract]
}

module "storage_blob_diagnostics" {
  source                     = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  for_each                   = { for key, account in local.enabled_storage_accounts : key => account if var.diagnostics.enabled && !contains(keys(var.diagnostics.existing_settings), "storage.${key}.blob") }
  name                       = "diag-${module.storage[each.key].name}-blob-law"
  target_resource_id         = "${module.storage[each.key].id}/blobServices/default"
  log_analytics_workspace_id = var.platform.log_analytics_workspace_id
  logs = {
    read   = { category = "StorageRead" }
    write  = { category = "StorageWrite" }
    delete = { category = "StorageDelete" }
  }
  metrics    = { transaction = { category = "Transaction" } }
  depends_on = [terraform_data.reuse_contract]
}

module "alert_contacts" {
  source              = "../../modules/terraform-azurerm-compeer-actiongroup"
  count               = local.create_action_group ? 1 : 0
  name                = "${local.workload_stem}-operations-ag"
  short_name          = substr("${var.appcode}-${var.environment}", 0, 12)
  resource_group_name = module.resource_groups.group_names["operations"]
  receivers = { email = { for email in var.operations.notification_emails : email => {
    email_address = email, use_common_alert_schema = true
  } } }
  tags       = module.tags.tags
  depends_on = [terraform_data.capability_contract]
}

# ON HOLD by default: OBS-09 is Phase 2; activate only with approved workload telemetry scope.
module "application_insights" {
  count                                 = local.create_application_insights ? 1 : 0
  source                                = "../../modules/terraform-azurerm-compeer-application-insights"
  name                                  = "${local.workload_stem}-appi"
  resource_group_name                   = module.resource_groups.group_names["operations"]
  location                              = var.location
  workspace_id                          = var.platform.log_analytics_workspace_id
  application_type                      = "other"
  sampling_percentage                   = local.environment_profile.telemetry_sampling_percentage
  retention_in_days                     = 90
  local_authentication_disabled         = true
  disable_ip_masking                    = false
  internet_ingestion_enabled            = var.monitoring.internet_ingestion_enabled
  internet_query_enabled                = var.monitoring.internet_query_enabled
  daily_data_cap_notifications_disabled = false
  tags                                  = module.tags.tags
  depends_on                            = [terraform_data.capability_contract]
}

module "telemetry_access" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"
  assignments = { for key in ["workload"] : key => {
    scope                            = local.application_insights_id
    principal_id                     = module.workload_identity.principal_id
    principal_type                   = "ServicePrincipal"
    role_definition_name             = "Monitoring Metrics Publisher"
    skip_service_principal_aad_check = true
  } if local.manage_telemetry_access }
  depends_on = [terraform_data.capability_contract]
}

# ON HOLD by default: OBS-04 workload alerts require approved recipients and SLOs.
module "failed_requests_alert" {
  count               = local.create_failed_requests_alert ? 1 : 0
  source              = "../../modules/terraform-azurerm-compeer-monitor-metric-alert"
  name                = "${local.workload_stem}-failed-requests"
  resource_group_name = module.resource_groups.group_names["operations"]
  scopes              = [local.application_insights_id]
  description         = "Application request failures exceeded the workload profile threshold; tune against the approved SLO."
  severity            = local.environment_profile.alert_severity
  frequency           = local.environment_profile.alert_frequency
  window_size         = "PT5M"
  criteria = {
    failed_requests = {
      metric_namespace = "Microsoft.Insights/components"
      metric_name      = "requests/failed"
      aggregation      = "Count"
      operator         = "GreaterThanOrEqual"
      threshold        = local.environment_profile.failed_request_threshold
    }
  }
  actions    = { for index, id in local.action_group_ids : "recipient-${index}" => { action_group_id = id } }
  tags       = module.tags.tags
  depends_on = [terraform_data.capability_contract]
}

resource "azurerm_backup_protected_vm" "workload" {
  for_each            = local.backup_enabled ? var.backup.virtual_machines : {}
  resource_group_name = try(split("/", var.backup.recovery_vault_id)[4], "")
  recovery_vault_name = try(split("/", var.backup.recovery_vault_id)[8], "")
  source_vm_id        = each.value
  backup_policy_id    = var.backup.backup_policy_id
  depends_on          = [terraform_data.capability_contract]
}
