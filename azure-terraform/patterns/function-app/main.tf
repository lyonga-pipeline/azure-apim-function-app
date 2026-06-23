module "tags" {
  source = "../../modules/platform-tags"

  environment         = var.environment
  application         = var.application.code
  business_owner      = var.application.business_owner
  source_repo         = var.application.source_repo
  terraform_workspace = var.application.terraform_workspace
  recovery_tier       = var.application.recovery_tier
  cost_center         = var.application.cost_center
  data_classification = var.application.data_classification
  compliance_boundary = var.application.compliance_boundary
  additional_tags     = var.application.additional_tags
}

resource "terraform_data" "contract" {
  input = true

  lifecycle {
    precondition {
      condition     = length(local.dependency_errors) == 0
      error_message = join("\n", local.dependency_errors)
    }
  }
}

module "resource_group" {
  source = "../../modules/resource-group"
  count  = local.create_resource_group ? 1 : 0

  name     = try(var.resource_group.create.name, null)
  location = var.location
  tags     = module.tags.tags
}

module "identity" {
  source = "../../modules/user-assigned-identity"
  count  = local.create_identity ? 1 : 0

  name                = try(var.identity.create.name, null)
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = module.tags.tags
}

module "app_service_plan" {
  source = "../../modules/app-service-plan"
  count  = local.create_app_service_plan ? 1 : 0

  name                   = try(var.app_service_plan.create.name, null)
  resource_group_name    = local.resource_group_name
  location               = var.location
  os_type                = try(var.app_service_plan.create.os_type, "Windows")
  sku_name               = try(var.app_service_plan.create.sku_name, null)
  worker_count           = try(var.app_service_plan.create.worker_count, null)
  zone_balancing_enabled = try(var.app_service_plan.create.zone_balancing_enabled, null)
  tags                   = module.tags.tags
}

module "storage_account" {
  source = "../../modules/storage-account"
  count  = local.create_storage_account ? 1 : 0

  name                              = try(var.storage_account.create.name, null)
  resource_group_name               = local.resource_group_name
  location                          = var.location
  account_replication_type          = try(var.storage_account.create.account_replication_type, "LRS")
  min_tls_version                   = "TLS1_2"
  public_network_access_enabled     = false
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  local_user_enabled                = false
  infrastructure_encryption_enabled = try(var.storage_account.create.infrastructure_encryption_enabled, true)
  default_to_oauth_authentication   = true
  network_rules = {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
  blob_properties = try(var.storage_account.create.blob_properties, null)
  tags            = module.tags.tags
}

module "storage_containers" {
  source = "../../modules/storage-container"

  storage_account_name = local.storage_account_name
  containers           = var.storage_account.containers
}

module "storage_queues" {
  source = "../../modules/storage-queue"

  storage_account_name = local.storage_account_name
  queues               = var.storage_account.queues
}

module "storage_shares" {
  source = "../../modules/storage-share"

  storage_account_name = local.storage_account_name
  shares               = var.storage_account.shares
}

module "key_vault" {
  source = "../../modules/key-vault"
  count  = local.create_key_vault ? 1 : 0

  name                          = try(var.key_vault.create.name, null)
  resource_group_name           = local.resource_group_name
  location                      = var.location
  tenant_id                     = var.tenant_id
  sku_name                      = try(var.key_vault.create.sku_name, "standard")
  soft_delete_retention_days    = try(var.key_vault.create.soft_delete_retention_days, 90)
  purge_protection_enabled      = try(var.key_vault.create.purge_protection_enabled, true)
  enable_rbac_authorization     = true
  public_network_access_enabled = false
  network_acls = {
    bypass         = "None"
    default_action = "Deny"
  }
  contacts = try(var.key_vault.create.contacts, {})
  tags     = module.tags.tags
}

module "key_vault_secrets" {
  source = "../../modules/key-vault-secret"

  key_vault_id = local.key_vault_id
  secrets      = var.key_vault.secrets
  tags         = module.tags.tags
}

module "application_insights" {
  source = "../../modules/application-insights"
  count  = local.create_application_insights ? 1 : 0

  name                          = try(var.application_insights.create.name, null)
  resource_group_name           = local.resource_group_name
  location                      = var.location
  application_type              = try(var.application_insights.create.application_type, "web")
  workspace_id                  = var.diagnostics.log_analytics_workspace_id
  retention_in_days             = try(var.application_insights.create.retention_in_days, 90)
  local_authentication_disabled = try(var.application_insights.create.local_authentication_disabled, true)
  tags                          = module.tags.tags
}

module "role_assignments" {
  source = "../../modules/role-assignments"

  assignments = try(var.role_assignments.enabled, true) ? merge(
    {
      key_vault_secrets_user = {
        scope                = local.key_vault_id
        principal_id         = local.identity_principal_id
        principal_type       = "ServicePrincipal"
        role_definition_name = "Key Vault Secrets User"
      }
      storage_blob_contributor = {
        scope                = local.storage_account_id
        principal_id         = local.identity_principal_id
        principal_type       = "ServicePrincipal"
        role_definition_name = "Storage Blob Data Contributor"
      }
      storage_queue_contributor = {
        scope                = local.storage_account_id
        principal_id         = local.identity_principal_id
        principal_type       = "ServicePrincipal"
        role_definition_name = "Storage Queue Data Contributor"
      }
    },
    var.role_assignments.additional
  ) : {}
}

module "function_app" {
  source = "../../modules/function-app"

  name                        = var.function_app.name
  resource_group_name         = local.resource_group_name
  location                    = var.location
  os_type                     = var.function_app.os_type
  service_plan_id             = local.app_service_plan_id
  functions_extension_version = var.function_app.functions_extension_version
  storage = {
    account_name          = local.storage_account_name
    uses_managed_identity = true
  }
  identity = {
    type         = "UserAssigned"
    identity_ids = [local.identity_id]
  }
  key_vault_reference_identity_id = local.identity_id
  public_network_access_enabled   = false
  https_only                      = true
  site_config = {
    always_on                              = var.function_app.always_on
    health_check_path                      = try(var.function_app.health_check_path, null)
    application_insights_connection_string = local.application_insights_connection_string
    http2_enabled                          = true
    minimum_tls_version                    = "1.2"
    scm_minimum_tls_version                = "1.2"
    ftps_state                             = "Disabled"
    vnet_route_all_enabled                 = true
    application_stack                      = var.function_app.application_stack
  }
  app_settings = merge(
    var.function_app.infrastructure_app_settings,
    local.platform_app_settings,
    var.function_app.runtime_app_settings,
  )
  tags = module.tags.tags

  depends_on = [
    terraform_data.contract,
    module.role_assignments,
  ]
}

module "function_vnet_integration" {
  source = "../../modules/app-service-vnet-integration"
  count  = try(var.network.app_service_integration_subnet_id, null) == null ? 0 : 1

  app_service_id = module.function_app.id
  subnet_id      = var.network.app_service_integration_subnet_id
}

module "private_endpoints" {
  source   = "../../modules/private-endpoint"
  for_each = local.private_endpoint_targets

  name                = each.value.name
  resource_group_name = local.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoints.subnet_id
  private_service_connection = {
    private_connection_resource_id = each.value.target_id
    subresource_names              = each.value.subresource_names
  }
  private_dns_zone_group = {
    private_dns_zone_ids = each.value.private_dns_zone_ids
  }
  tags = module.tags.tags

  depends_on = [terraform_data.contract]
}

module "diagnostic_settings" {
  source   = "../../modules/diagnostic-settings"
  for_each = try(var.diagnostics.enabled, true) ? local.diagnostic_targets : {}

  name                       = "${each.key}-diag"
  target_resource_id         = each.value
  log_analytics_workspace_id = var.diagnostics.log_analytics_workspace_id
  logs                       = var.diagnostics.logs
  metrics                    = var.diagnostics.metrics

  depends_on = [terraform_data.contract]
}

module "function_http_5xx_alert" {
  source = "../../modules/monitor-metric-alert"
  count  = try(var.alerts.enabled, true) ? 1 : 0

  name                = "${var.function_app.name}-http5xx-alert"
  resource_group_name = local.resource_group_name
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
      action_group_id = var.alerts.action_group_id
    }
  }
  tags = module.tags.tags

  depends_on = [terraform_data.contract]
}
