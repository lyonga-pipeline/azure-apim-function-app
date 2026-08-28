module "resource_groups" {
  for_each = local.rg_names
  source   = "Azure/avm-res-resources-resourcegroup/azurerm"
  version  = "0.4.0"

  name             = each.value
  location         = var.location
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
  lock             = local.lock
}

module "platform_identity" {
  source  = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version = "0.5.2"

  name                = "${var.prefix}-${var.environment}-cus-platform-uami"
  location            = var.location
  resource_group_name = module.resource_groups["security"].name
  tags                = local.tags
  enable_telemetry    = var.enable_telemetry
  lock                = local.lock
}

module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                                                 = "${var.prefix}-${var.environment}-cus-law"
  location                                             = var.location
  resource_group_name                                  = module.resource_groups["management"].name
  log_analytics_workspace_retention_in_days            = var.log_retention_days
  log_analytics_workspace_sku                          = "PerGB2018"
  log_analytics_workspace_internet_ingestion_enabled   = false
  log_analytics_workspace_internet_query_enabled       = false
  log_analytics_workspace_local_authentication_enabled = false
  tags                                                 = local.tags
  enable_telemetry                                     = var.enable_telemetry
  lock                                                 = local.lock
}

module "key_vault" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-keyvault/azurerm"
  version = "1.0.6"

  name                = substr(replace("${var.prefix}-${var.environment}-cus-platform-kv", "_", "-"), 0, 24)
  location            = var.location
  resource_group_name = module.resource_groups["security"].name
  sku_name            = "premium"

  public_network_access_enabled   = false
  purge_protection_enabled        = true
  soft_delete_retention_days      = 90
  rbac_authorization_enabled      = true
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = false
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
  tags = local.tags
}

module "key_vault_rbac" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-role-assignments/azurerm"
  version = "1.0.0"

  assignments = {
    for id in var.key_vault_admin_principal_ids : "kv-admin-${id}" => {
      scope                = module.key_vault.id
      role_definition_name = "Key Vault Administrator"
      principal_id         = id
      principal_type       = "ServicePrincipal"
    }
  }
}

module "key_vault_diagnostics" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-diagnostic-settings/azurerm"
  version = "1.0.0"

  name                       = "${var.prefix}-${var.environment}-cus-platform-kv-law"
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = module.log_analytics.resource_id
  logs = {
    all = { category_group = "allLogs" }
  }
  metrics = {
    all = { category = "AllMetrics" }
  }
}

module "key_vault_private_endpoint" {
  count   = var.platform_private_endpoint_subnet_id == null ? 0 : 1
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-private-endpoint/azurerm"
  version = "1.0.5"

  name                          = "${var.prefix}-${var.environment}-cus-platform-kv-pe"
  custom_network_interface_name = "${var.prefix}-${var.environment}-cus-platform-kv-pe-nic"
  resource_group_name           = module.resource_groups["security"].name
  location                      = var.location
  subnet_id                     = var.platform_private_endpoint_subnet_id
  private_service_connections = [
    {
      name                           = "${var.prefix}-${var.environment}-cus-platform-kv-psc"
      is_manual_connection           = false
      private_connection_resource_id = module.key_vault.id
      subresource_names              = ["vault"]
    }
  ]
  private_dns_zone_group = length(var.key_vault_private_dns_zone_ids) == 0 ? [] : [
    {
      name                 = "default"
      private_dns_zone_ids = var.key_vault_private_dns_zone_ids
    }
  ]
  tags = local.tags
}

module "platform_storage" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-storage-account/azurerm"
  version = "1.3.3"

  name                = substr(replace("${var.prefix}${var.environment}cuspltst", "-", ""), 0, 24)
  location            = var.location
  resource_group_name = module.resource_groups["management"].name

  account_tier                      = "Standard"
  account_replication_type          = "ZRS"
  account_kind                      = "StorageV2"
  min_tls_version                   = "TLS1_2"
  public_network_access_enabled     = false
  shared_access_key_enabled         = false
  infrastructure_encryption_enabled = true
  allow_nested_items_to_be_public   = false
  default_to_oauth_authentication   = true
  cross_tenant_replication_enabled  = false
  blob_properties = {
    versioning_enabled              = true
    change_feed_enabled             = true
    last_access_time_enabled        = false
    delete_retention_days           = 7
    container_delete_retention_days = 7
  }
  tags = local.tags
}

module "platform_storage_diagnostics" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-diagnostic-settings/azurerm"
  version = "1.0.0"

  name                       = "${var.prefix}-${var.environment}-cus-platform-st-law"
  target_resource_id         = module.platform_storage.id
  log_analytics_workspace_id = module.log_analytics.resource_id
  logs = {
    all = { category_group = "allLogs" }
  }
  metrics = {
    transaction = { category = "Transaction" }
  }
}

module "platform_storage_private_endpoint" {
  for_each = var.platform_private_endpoint_subnet_id == null ? {} : var.platform_storage_private_endpoints
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-private-endpoint/azurerm"
  version  = "1.0.5"

  name                          = "${var.prefix}-${var.environment}-cus-platform-st-${each.key}-pe"
  custom_network_interface_name = "${var.prefix}-${var.environment}-cus-platform-st-${each.key}-pe-nic"
  resource_group_name           = module.resource_groups["management"].name
  location                      = var.location
  subnet_id                     = var.platform_private_endpoint_subnet_id
  private_service_connections = [
    {
      name                           = "${var.prefix}-${var.environment}-cus-platform-st-${each.key}-psc"
      is_manual_connection           = false
      private_connection_resource_id = module.platform_storage.id
      subresource_names              = [each.value.subresource_name]
    }
  ]
  private_dns_zone_group = length(each.value.private_dns_zone_ids) == 0 ? [] : [
    {
      name                 = "default"
      private_dns_zone_ids = each.value.private_dns_zone_ids
    }
  ]
  tags = local.tags
}

module "recovery_services_vault" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-recovery-services-vault/azurerm"
  version = "1.0.0"

  name                = "${var.prefix}-${var.environment}-cus-rsv"
  location            = var.location
  resource_group_name = module.resource_groups["management"].name
  sku                 = "Standard"
  storage_mode_type   = "ZoneRedundant"
  soft_delete_enabled = true
  tags                = local.tags
}

module "recovery_services_vault_diagnostics" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-diagnostic-settings/azurerm"
  version = "1.0.0"

  name                       = "${var.prefix}-${var.environment}-cus-rsv-law"
  target_resource_id         = module.recovery_services_vault.id
  log_analytics_workspace_id = module.log_analytics.resource_id
  logs = {
    all = { category_group = "allLogs" }
  }
  metrics = {
    all = { category = "AllMetrics" }
  }
}

# Workbook SEC-01/SEC-02: Sentinel onboarding and connector target-state are
# Compeer HCP modules because AVM does not provide a stable Sentinel resource.
module "sentinel" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-sentinel/azurerm"
  version = "1.0.0"

  enabled                    = var.sentinel_enabled
  log_analytics_workspace_id = module.log_analytics.resource_id
  approved_data_connectors   = var.sentinel_data_connectors
}

module "defender_soc_posture" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-defender-soc-posture/azurerm"
  version = "1.0.0"

  enabled                  = var.defender_enabled
  defender_plans           = var.defender_plans
  security_contact         = var.security_contact
  security_center_settings = var.security_center_settings
  posture_contract         = var.soc_posture_contract
}
