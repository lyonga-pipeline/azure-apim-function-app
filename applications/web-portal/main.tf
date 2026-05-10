locals {
  name_prefix = "${var.application_name}-${var.environment}"
  common_tags = merge(var.tags, {
    application = var.application_name
    environment = var.environment
  })
}

module "resource_group" {
  source   = "../../azure-terraform/modules/resource-group"
  name     = try(var.resource_group.name, "${local.name_prefix}-rg")
  location = var.location
  tags     = merge(local.common_tags, try(var.resource_group.tags, {}))
}

module "log_analytics" {
  source                             = "../../azure-terraform/modules/log-analytics"
  name                               = try(var.log_analytics.name, "${local.name_prefix}-law")
  resource_group_name                = module.resource_group.name
  location                           = module.resource_group.location
  sku                                = try(var.log_analytics.sku, null)
  retention_in_days                  = try(var.log_analytics.retention_in_days, null)
  daily_quota_gb                     = try(var.log_analytics.daily_quota_gb, null)
  internet_ingestion_enabled         = try(var.log_analytics.internet_ingestion_enabled, null)
  internet_query_enabled             = try(var.log_analytics.internet_query_enabled, null)
  reservation_capacity_in_gb_per_day = try(var.log_analytics.reservation_capacity_in_gb_per_day, null)
  cmk_for_query_forced               = try(var.log_analytics.cmk_for_query_forced, null)
  tags                               = merge(local.common_tags, try(var.log_analytics.tags, {}))
}

module "application_insights" {
  source                                = "../../azure-terraform/modules/application-insights"
  name                                  = try(var.application_insights.name, "${local.name_prefix}-appi")
  resource_group_name                   = module.resource_group.name
  location                              = module.resource_group.location
  application_type                      = try(var.application_insights.application_type, null)
  workspace_id                          = module.log_analytics.id
  daily_data_cap_in_gb                  = try(var.application_insights.daily_data_cap_in_gb, null)
  daily_data_cap_notifications_disabled = try(var.application_insights.daily_data_cap_notifications_disabled, null)
  retention_in_days                     = try(var.application_insights.retention_in_days, null)
  sampling_percentage                   = try(var.application_insights.sampling_percentage, null)
  disable_ip_masking                    = try(var.application_insights.disable_ip_masking, null)
  local_authentication_disabled         = try(var.application_insights.local_authentication_disabled, null)
  internet_ingestion_enabled            = try(var.application_insights.internet_ingestion_enabled, null)
  internet_query_enabled                = try(var.application_insights.internet_query_enabled, null)
  force_customer_storage_for_profiler   = try(var.application_insights.force_customer_storage_for_profiler, null)
  tags                                  = merge(local.common_tags, try(var.application_insights.tags, {}))
}

module "virtual_network" {
  source              = "../../azure-terraform/modules/virtual-network"
  name                = try(var.virtual_network.name, "${local.name_prefix}-vnet")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = var.virtual_network.address_space
  dns_servers         = try(var.virtual_network.dns_servers, null)
  subnets             = try(var.virtual_network.subnets, {})
  tags                = merge(local.common_tags, try(var.virtual_network.tags, {}))
}

module "private_dns_zones" {
  source = "../../azure-terraform/modules/private-dns-zone"
  zones  = var.private_dns_zones
  tags   = local.common_tags
}

module "private_dns_links" {
  source = "../../azure-terraform/modules/private-dns-vnet-link"
  links = {
    for key, value in var.private_dns_links :
    key => merge(value, {
      virtual_network_id = module.virtual_network.id
    })
  }
  tags = local.common_tags
}

module "key_vault" {
  source                        = "../../azure-terraform/modules/key-vault"
  name                          = try(var.key_vault.name, "${local.name_prefix}-kv")
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  tenant_id                     = var.tenant_id
  sku_name                      = try(var.key_vault.sku_name, null)
  soft_delete_retention_days    = try(var.key_vault.soft_delete_retention_days, null)
  purge_protection_enabled      = try(var.key_vault.purge_protection_enabled, null)
  enable_rbac_authorization     = try(var.key_vault.enable_rbac_authorization, null)
  public_network_access_enabled = try(var.key_vault.public_network_access_enabled, null)
  network_acls                  = try(var.key_vault.network_acls, {})
  contacts                      = try(var.key_vault.contacts, {})
  tags                          = merge(local.common_tags, try(var.key_vault.tags, {}))
}

module "key_vault_keys" {
  source       = "../../azure-terraform/modules/key-vault-key"
  key_vault_id = module.key_vault.id
  keys         = var.key_vault_keys
  tags         = local.common_tags
}

module "key_vault_secrets" {
  source       = "../../azure-terraform/modules/key-vault-secret"
  key_vault_id = module.key_vault.id
  secrets      = var.key_vault_secrets
  tags         = local.common_tags
}

module "storage_account" {
  source                            = "../../azure-terraform/modules/storage-account"
  name                              = var.storage_account.name
  resource_group_name               = module.resource_group.name
  location                          = module.resource_group.location
  account_tier                      = try(var.storage_account.account_tier, null)
  account_replication_type          = try(var.storage_account.account_replication_type, null)
  account_kind                      = try(var.storage_account.account_kind, null)
  access_tier                       = try(var.storage_account.access_tier, null)
  min_tls_version                   = try(var.storage_account.min_tls_version, null)
  public_network_access_enabled     = try(var.storage_account.public_network_access_enabled, null)
  allow_nested_items_to_be_public   = try(var.storage_account.allow_nested_items_to_be_public, null)
  shared_access_key_enabled         = try(var.storage_account.shared_access_key_enabled, null)
  infrastructure_encryption_enabled = try(var.storage_account.infrastructure_encryption_enabled, null)
  is_hns_enabled                    = try(var.storage_account.is_hns_enabled, null)
  sftp_enabled                      = try(var.storage_account.sftp_enabled, null)
  nfsv3_enabled                     = try(var.storage_account.nfsv3_enabled, null)
  large_file_share_enabled          = try(var.storage_account.large_file_share_enabled, null)
  cross_tenant_replication_enabled  = try(var.storage_account.cross_tenant_replication_enabled, null)
  default_to_oauth_authentication   = try(var.storage_account.default_to_oauth_authentication, null)
  identity                          = try(var.storage_account.identity, null)
  network_rules                     = try(var.storage_account.network_rules, null)
  blob_properties                   = try(var.storage_account.blob_properties, null)
  queue_properties                  = try(var.storage_account.queue_properties, null)
  static_website                    = try(var.storage_account.static_website, null)
  tags                              = merge(local.common_tags, try(var.storage_account.tags, {}))
}

module "storage_cmk" {
  source                       = "../../azure-terraform/modules/storage-account-customer-managed-key"
  storage_account_id           = module.storage_account.id
  key_vault_key_id             = module.key_vault_keys.ids[var.storage_cmk.key_name]
  user_assigned_identity_id    = try(var.storage_cmk.user_assigned_identity_id, null)
  federated_identity_client_id = try(var.storage_cmk.federated_identity_client_id, null)
}

module "storage_management_policy" {
  source             = "../../azure-terraform/modules/storage-management-policy"
  storage_account_id = module.storage_account.id
  rules              = var.storage_management_rules
}

module "storage_containers" {
  source               = "../../azure-terraform/modules/storage-container"
  storage_account_name = module.storage_account.name
  containers           = var.storage_containers
}

module "storage_shares" {
  source               = "../../azure-terraform/modules/storage-share"
  storage_account_name = module.storage_account.name
  shares               = var.storage_shares
}

module "storage_blobs" {
  source               = "../../azure-terraform/modules/storage-blob"
  storage_account_name = module.storage_account.name
  blobs                = var.storage_blobs
}

module "app_service_plan" {
  source                       = "../../azure-terraform/modules/app-service-plan"
  name                         = try(var.app_service_plan.name, "${local.name_prefix}-plan")
  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  os_type                      = var.app_service_plan.os_type
  sku_name                     = var.app_service_plan.sku_name
  worker_count                 = try(var.app_service_plan.worker_count, null)
  maximum_elastic_worker_count = try(var.app_service_plan.maximum_elastic_worker_count, null)
  per_site_scaling_enabled     = try(var.app_service_plan.per_site_scaling_enabled, null)
  zone_balancing_enabled       = try(var.app_service_plan.zone_balancing_enabled, null)
  tags                         = merge(local.common_tags, try(var.app_service_plan.tags, {}))
}

module "web_app" {
  source                                         = "../../azure-terraform/modules/web-app"
  name                                           = try(var.web_app.name, "${local.name_prefix}-web")
  resource_group_name                            = module.resource_group.name
  location                                       = module.resource_group.location
  os_type                                        = var.web_app.os_type
  service_plan_id                                = module.app_service_plan.id
  public_network_access_enabled                  = try(var.web_app.public_network_access_enabled, null)
  https_only                                     = try(var.web_app.https_only, null)
  enabled                                        = try(var.web_app.enabled, null)
  client_affinity_enabled                        = try(var.web_app.client_affinity_enabled, null)
  client_certificate_enabled                     = try(var.web_app.client_certificate_enabled, null)
  client_certificate_mode                        = try(var.web_app.client_certificate_mode, null)
  client_certificate_exclusion_paths             = try(var.web_app.client_certificate_exclusion_paths, null)
  key_vault_reference_identity_id                = try(var.web_app.key_vault_reference_identity_id, null)
  virtual_network_backup_restore_enabled         = try(var.web_app.virtual_network_backup_restore_enabled, null)
  ftp_publish_basic_authentication_enabled       = try(var.web_app.ftp_publish_basic_authentication_enabled, null)
  webdeploy_publish_basic_authentication_enabled = try(var.web_app.webdeploy_publish_basic_authentication_enabled, null)
  identity                                       = try(var.web_app.identity, null)
  site_config = merge(try(var.web_app.site_config, {}), {
    application_stack = try(var.web_app.site_config.application_stack, null)
  })
  connection_strings = try(var.web_app.connection_strings, {})
  sticky_settings    = try(var.web_app.sticky_settings, null)
  auth_settings_v2   = try(var.web_app.auth_settings_v2, null)
  app_settings = merge(
    try(var.web_app.app_settings, {}),
    {
      APPINSIGHTS_CONNECTION_STRING = module.application_insights.connection_string
      KEY_VAULT_URI                 = module.key_vault.vault_uri
      STORAGE_ACCOUNT_NAME          = module.storage_account.name
    }
  )
  tags = merge(local.common_tags, try(var.web_app.tags, {}))
}

module "web_app_slot" {
  source                        = "../../azure-terraform/modules/web-app-slot"
  name                          = try(var.web_app_slot.name, "staging")
  app_service_id                = module.web_app.id
  os_type                       = var.web_app_slot.os_type
  service_plan_id               = module.app_service_plan.id
  public_network_access_enabled = try(var.web_app_slot.public_network_access_enabled, null)
  https_only                    = try(var.web_app_slot.https_only, null)
  enabled                       = try(var.web_app_slot.enabled, null)
  client_affinity_enabled       = try(var.web_app_slot.client_affinity_enabled, null)
  client_certificate_enabled    = try(var.web_app_slot.client_certificate_enabled, null)
  client_certificate_mode       = try(var.web_app_slot.client_certificate_mode, null)
  identity                      = try(var.web_app_slot.identity, null)
  site_config                   = try(var.web_app_slot.site_config, {})
  connection_strings            = try(var.web_app_slot.connection_strings, {})
  app_settings                  = merge(try(var.web_app_slot.app_settings, {}), { SLOT_NAME = try(var.web_app_slot.name, "staging") })
  tags                          = merge(local.common_tags, try(var.web_app_slot.tags, {}))
}

module "web_app_vnet_integration" {
  source         = "../../azure-terraform/modules/app-service-vnet-integration"
  app_service_id = module.web_app.id
  subnet_id      = module.virtual_network.subnet_ids[var.web_app.integration_subnet_name]
}

module "web_app_to_key_vault_role" {
  source = "../../azure-terraform/modules/role-assignments"
  assignments = {
    web-app-kv = {
      scope                = module.key_vault.id
      principal_id         = module.web_app.identity[0].principal_id
      role_definition_name = var.web_app_key_vault_role_name
      principal_type       = "ServicePrincipal"
    }
  }
}

module "web_app_to_storage_role" {
  source = "../../azure-terraform/modules/role-assignments"
  assignments = {
    web-app-storage = {
      scope                = module.storage_account.id
      principal_id         = module.web_app.identity[0].principal_id
      role_definition_name = var.web_app_storage_role_name
      principal_type       = "ServicePrincipal"
    }
  }
}

module "storage_cmk_role" {
  source = "../../azure-terraform/modules/role-assignments"
  assignments = {
    storage-cmk = {
      scope                = module.key_vault.id
      principal_id         = var.storage_cmk.user_assigned_identity_principal_id
      role_definition_name = var.storage_cmk_role_name
      principal_type       = "ServicePrincipal"
    }
  }
}

module "web_app_private_endpoint" {
  source                        = "../../azure-terraform/modules/private-endpoint"
  name                          = try(var.web_app_private_endpoint.name, "${local.name_prefix}-web-pe")
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  subnet_id                     = module.virtual_network.subnet_ids[var.web_app_private_endpoint.subnet_name]
  custom_network_interface_name = try(var.web_app_private_endpoint.custom_network_interface_name, null)
  private_service_connection    = merge(var.web_app_private_endpoint.private_service_connection, { private_connection_resource_id = module.web_app.id })
  private_dns_zone_group        = try(var.web_app_private_endpoint.private_dns_zone_group, null)
  ip_configurations             = try(var.web_app_private_endpoint.ip_configurations, {})
  tags                          = merge(local.common_tags, try(var.web_app_private_endpoint.tags, {}))
}

module "key_vault_private_endpoint" {
  source                        = "../../azure-terraform/modules/private-endpoint"
  name                          = try(var.key_vault_private_endpoint.name, "${local.name_prefix}-kv-pe")
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  subnet_id                     = module.virtual_network.subnet_ids[var.key_vault_private_endpoint.subnet_name]
  custom_network_interface_name = try(var.key_vault_private_endpoint.custom_network_interface_name, null)
  private_service_connection    = merge(var.key_vault_private_endpoint.private_service_connection, { private_connection_resource_id = module.key_vault.id })
  private_dns_zone_group        = try(var.key_vault_private_endpoint.private_dns_zone_group, null)
  ip_configurations             = try(var.key_vault_private_endpoint.ip_configurations, {})
  tags                          = merge(local.common_tags, try(var.key_vault_private_endpoint.tags, {}))
}

module "storage_blob_private_endpoint" {
  source                        = "../../azure-terraform/modules/private-endpoint"
  name                          = try(var.storage_blob_private_endpoint.name, "${local.name_prefix}-blob-pe")
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  subnet_id                     = module.virtual_network.subnet_ids[var.storage_blob_private_endpoint.subnet_name]
  custom_network_interface_name = try(var.storage_blob_private_endpoint.custom_network_interface_name, null)
  private_service_connection    = merge(var.storage_blob_private_endpoint.private_service_connection, { private_connection_resource_id = module.storage_account.id })
  private_dns_zone_group        = try(var.storage_blob_private_endpoint.private_dns_zone_group, null)
  ip_configurations             = try(var.storage_blob_private_endpoint.ip_configurations, {})
  tags                          = merge(local.common_tags, try(var.storage_blob_private_endpoint.tags, {}))
}

module "storage_file_private_endpoint" {
  source                        = "../../azure-terraform/modules/private-endpoint"
  name                          = try(var.storage_file_private_endpoint.name, "${local.name_prefix}-file-pe")
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  subnet_id                     = module.virtual_network.subnet_ids[var.storage_file_private_endpoint.subnet_name]
  custom_network_interface_name = try(var.storage_file_private_endpoint.custom_network_interface_name, null)
  private_service_connection    = merge(var.storage_file_private_endpoint.private_service_connection, { private_connection_resource_id = module.storage_account.id })
  private_dns_zone_group        = try(var.storage_file_private_endpoint.private_dns_zone_group, null)
  ip_configurations             = try(var.storage_file_private_endpoint.ip_configurations, {})
  tags                          = merge(local.common_tags, try(var.storage_file_private_endpoint.tags, {}))
}

module "web_app_diagnostics" {
  source                     = "../../azure-terraform/modules/diagnostic-settings"
  name                       = try(var.web_app_diagnostics.name, "${local.name_prefix}-web-diag")
  target_resource_id         = module.web_app.id
  log_analytics_workspace_id = module.log_analytics.id
  logs                       = try(var.web_app_diagnostics.logs, {})
  metrics                    = try(var.web_app_diagnostics.metrics, {})
}

module "key_vault_diagnostics" {
  source                     = "../../azure-terraform/modules/diagnostic-settings"
  name                       = try(var.key_vault_diagnostics.name, "${local.name_prefix}-kv-diag")
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = module.log_analytics.id
  logs                       = try(var.key_vault_diagnostics.logs, {})
  metrics                    = try(var.key_vault_diagnostics.metrics, {})
}

module "storage_diagnostics" {
  source                     = "../../azure-terraform/modules/diagnostic-settings"
  name                       = try(var.storage_diagnostics.name, "${local.name_prefix}-stg-diag")
  target_resource_id         = module.storage_account.id
  log_analytics_workspace_id = module.log_analytics.id
  logs                       = try(var.storage_diagnostics.logs, {})
  metrics                    = try(var.storage_diagnostics.metrics, {})
}
