module "tags" {
  source  = "app.terraform.io/compeer/compeer-platform-tags/azurerm"
  version = "2.2.0"

  environment         = var.environment
  application         = var.application.code
  business_owner      = var.application.business_owner
  source_repo         = var.application.source_repo
  terraform_workspace = "online-banking-${var.environment}"
  recovery_tier       = "standard"
  cost_center         = var.application.cost_center
  data_classification = var.application.data_classification
  compliance_boundary = var.application.compliance_boundary
  additional_tags     = var.additional_tags
}

module "resource_group" {
  source  = "app.terraform.io/compeer/compeer-resource-group/azurerm"
  version = "2.2.0"

  name     = var.resource_group.name
  location = var.location
  tags     = module.tags.tags
}

module "workload_identity" {
  source  = "app.terraform.io/compeer/compeer-user-assigned-identity/azurerm"
  version = "2.2.0"

  name                = var.identity.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = module.tags.tags
}

module "application_insights" {
  source  = "app.terraform.io/compeer/compeer-application-insights/azurerm"
  version = "2.2.0"

  name                          = "${local.name_prefix}-appi"
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  application_type              = "web"
  workspace_id                  = var.shared.log_analytics_workspace_id
  local_authentication_disabled = true
  tags                          = module.tags.tags
}

module "key_vault" {
  source  = "app.terraform.io/compeer/compeer-key-vault/azurerm"
  version = "2.2.0"

  name                          = var.key_vault.name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  tenant_id                     = var.tenant_id
  sku_name                      = var.key_vault.sku_name
  soft_delete_retention_days    = var.key_vault.soft_delete_retention_days
  purge_protection_enabled      = var.key_vault.purge_protection_enabled
  enable_rbac_authorization     = true
  public_network_access_enabled = false
  network_acls = {
    bypass         = "None"
    default_action = "Deny"
  }
  contacts = try(var.key_vault.contacts, {})
  tags     = module.tags.tags
}

module "key_vault_secrets" {
  source  = "app.terraform.io/compeer/compeer-key-vault-secret/azurerm"
  version = "2.2.0"

  key_vault_id = module.key_vault.id
  secrets      = var.key_vault_secrets
  tags         = module.tags.tags
}

module "storage_account" {
  source  = "app.terraform.io/compeer/compeer-storage-account/azurerm"
  version = "2.2.0"

  name                              = var.storage_account.name
  resource_group_name               = module.resource_group.name
  location                          = module.resource_group.location
  account_replication_type          = var.storage_account.account_replication_type
  public_network_access_enabled     = false
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  infrastructure_encryption_enabled = true
  default_to_oauth_authentication   = true
  blob_properties = {
    versioning_enabled              = true
    change_feed_enabled             = true
    delete_retention_days           = 30
    container_delete_retention_days = 30
  }
  tags = module.tags.tags
}

module "storage_containers" {
  source  = "app.terraform.io/compeer/compeer-storage-container/azurerm"
  version = "2.2.0"

  storage_account_name = module.storage_account.name
  containers           = var.storage_account.containers
}

module "storage_queues" {
  source  = "app.terraform.io/compeer/compeer-storage-queue/azurerm"
  version = "2.2.0"

  storage_account_name = module.storage_account.name
  queues               = var.storage_account.queues
}

module "storage_shares" {
  source  = "app.terraform.io/compeer/compeer-storage-share/azurerm"
  version = "2.2.0"

  storage_account_name = module.storage_account.name
  shares               = var.storage_account.shares
}

module "role_assignments" {
  source  = "app.terraform.io/compeer/compeer-role-assignments/azurerm"
  version = "2.2.0"

  assignments = {
    key_vault_secrets_user = {
      scope                = module.key_vault.id
      principal_id         = module.workload_identity.principal_id
      principal_type       = "ServicePrincipal"
      role_definition_name = "Key Vault Secrets User"
    }
    storage_blob_contributor = {
      scope                = module.storage_account.id
      principal_id         = module.workload_identity.principal_id
      principal_type       = "ServicePrincipal"
      role_definition_name = "Storage Blob Data Contributor"
    }
    storage_queue_contributor = {
      scope                = module.storage_account.id
      principal_id         = module.workload_identity.principal_id
      principal_type       = "ServicePrincipal"
      role_definition_name = "Storage Queue Data Contributor"
    }
  }
}

module "app_service_plan" {
  source  = "app.terraform.io/compeer/compeer-app-service-plan/azurerm"
  version = "2.2.0"

  name                   = var.app_service_plan.name
  resource_group_name    = module.resource_group.name
  location               = module.resource_group.location
  os_type                = var.app_service_plan.os_type
  sku_name               = var.app_service_plan.sku_name
  worker_count           = try(var.app_service_plan.worker_count, null)
  zone_balancing_enabled = try(var.app_service_plan.zone_balancing_enabled, null)
  tags                   = module.tags.tags
}

module "function_app" {
  source  = "app.terraform.io/compeer/compeer-function-app/azurerm"
  version = "2.2.0"

  name                        = var.function_app.name
  resource_group_name         = module.resource_group.name
  location                    = module.resource_group.location
  os_type                     = var.function_app.os_type
  service_plan_id             = module.app_service_plan.id
  functions_extension_version = var.function_app.functions_extension_version
  storage = {
    account_name          = module.storage_account.name
    uses_managed_identity = true
  }
  identity = {
    type         = "UserAssigned"
    identity_ids = [module.workload_identity.id]
  }
  key_vault_reference_identity_id = module.workload_identity.id
  public_network_access_enabled   = false
  https_only                      = true
  site_config = {
    always_on                              = var.function_app.always_on
    health_check_path                      = var.function_app.health_check_path
    application_insights_connection_string = module.application_insights.connection_string
    http2_enabled                          = true
    minimum_tls_version                    = "1.2"
    scm_minimum_tls_version                = "1.2"
    ftps_state                             = "Disabled"
    vnet_route_all_enabled                 = true
    application_stack                      = var.function_app.application_stack
  }
  app_settings = merge(var.function_app.app_settings, local.common_app_settings)
  tags         = module.tags.tags

  depends_on = [module.role_assignments]
}

module "function_vnet_integration" {
  source  = "app.terraform.io/compeer/compeer-app-service-vnet-integration/azurerm"
  version = "2.2.0"

  app_service_id = module.function_app.id
  subnet_id      = var.shared.subnet_ids.app_integration
}

module "private_endpoints" {
  source  = "app.terraform.io/compeer/compeer-private-endpoint/azurerm"
  version = "2.2.0"

  for_each = local.private_endpoints

  name                = each.value.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = var.shared.subnet_ids.private_endpoint
  private_service_connection = {
    private_connection_resource_id = each.value.target_id
    subresource_names              = each.value.subresource_names
  }
  private_dns_zone_group = {
    private_dns_zone_ids = each.value.dns_zone_ids
  }
  tags = module.tags.tags
}

module "diagnostic_settings" {
  source  = "app.terraform.io/compeer/compeer-diagnostic-settings/azurerm"
  version = "2.2.0"

  for_each = local.diagnostic_targets

  name                       = "${each.key}-diag"
  target_resource_id         = each.value
  log_analytics_workspace_id = var.shared.log_analytics_workspace_id
  logs                       = var.diagnostics.logs
  metrics                    = var.diagnostics.metrics
}

module "function_http_5xx_alert" {
  source  = "app.terraform.io/compeer/compeer-monitor-metric-alert/azurerm"
  version = "2.2.0"

  name                = "${local.name_prefix}-http5xx-alert"
  resource_group_name = module.resource_group.name
  scopes              = toset([module.function_app.id])
  severity            = var.alerts.severity
  frequency           = var.alerts.frequency
  window_size         = var.alerts.window_size
  criteria = {
    http_5xx = {
      metric_namespace = "Microsoft.Web/sites"
      metric_name      = "Http5xx"
      aggregation      = "Total"
      operator         = "GreaterThan"
      threshold        = var.alerts.http_5xx_threshold
    }
  }
  actions = {
    primary = {
      action_group_id = var.shared.action_group_id
    }
  }
  tags = module.tags.tags
}
