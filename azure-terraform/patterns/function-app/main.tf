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

locals {
  dependency_errors = compact([
    contains(["create", "existing"], lower(var.resource_group.mode)) ? null : "resource_group.mode must be create or existing.",
    lower(var.resource_group.mode) == "create" && try(var.resource_group.create.name, null) == null ? "resource_group.create.name is required when resource_group.mode is create." : null,
    lower(var.resource_group.mode) == "existing" && try(var.resource_group.existing.name, null) == null ? "resource_group.existing.name is required when resource_group.mode is existing." : null,

    contains(["create", "existing"], lower(var.identity.mode)) ? null : "identity.mode must be create or existing.",
    lower(var.identity.mode) == "create" && try(var.identity.create.name, null) == null ? "identity.create.name is required when identity.mode is create." : null,
    lower(var.identity.mode) == "existing" && (try(var.identity.existing.id, null) == null || try(var.identity.existing.principal_id, null) == null) ? "identity.existing.id and identity.existing.principal_id are required when identity.mode is existing." : null,

    contains(["create", "existing"], lower(var.app_service_plan.mode)) ? null : "app_service_plan.mode must be create or existing.",
    lower(var.app_service_plan.mode) == "create" && (try(var.app_service_plan.create.name, null) == null || try(var.app_service_plan.create.sku_name, null) == null) ? "app_service_plan.create.name and app_service_plan.create.sku_name are required when app_service_plan.mode is create." : null,
    lower(var.app_service_plan.mode) == "existing" && try(var.app_service_plan.existing.id, null) == null ? "app_service_plan.existing.id is required when app_service_plan.mode is existing." : null,

    contains(["create", "existing"], lower(var.storage_account.mode)) ? null : "storage_account.mode must be create or existing.",
    lower(var.storage_account.mode) == "create" && try(var.storage_account.create.name, null) == null ? "storage_account.create.name is required when storage_account.mode is create." : null,
    lower(var.storage_account.mode) == "existing" && (try(var.storage_account.existing.id, null) == null || try(var.storage_account.existing.name, null) == null) ? "storage_account.existing.id and storage_account.existing.name are required when storage_account.mode is existing." : null,

    contains(["create", "existing"], lower(var.key_vault.mode)) ? null : "key_vault.mode must be create or existing.",
    lower(var.key_vault.mode) == "create" && try(var.key_vault.create.name, null) == null ? "key_vault.create.name is required when key_vault.mode is create." : null,
    lower(var.key_vault.mode) == "existing" && (try(var.key_vault.existing.id, null) == null || try(var.key_vault.existing.vault_uri, null) == null) ? "key_vault.existing.id and key_vault.existing.vault_uri are required when key_vault.mode is existing." : null,

    contains(["create", "existing"], lower(var.application_insights.mode)) ? null : "application_insights.mode must be create or existing.",
    lower(var.application_insights.mode) == "create" && try(var.application_insights.create.name, null) == null ? "application_insights.create.name is required when application_insights.mode is create." : null,
    lower(var.application_insights.mode) == "existing" && (try(var.application_insights.existing.id, null) == null || try(var.application_insights.existing.connection_string, null) == null) ? "application_insights.existing.id and application_insights.existing.connection_string are required when application_insights.mode is existing." : null,

    try(var.private_endpoints.enabled, true) && try(var.private_endpoints.subnet_id, null) == null ? "private_endpoints.subnet_id is required when private_endpoints.enabled is true." : null,
    try(var.private_endpoints.enabled, true) && try(var.private_endpoints.targets.function_app, true) && try(var.private_endpoints.private_dns_zone_ids.app_service, null) == null ? "private_endpoints.private_dns_zone_ids.app_service is required when the Function App private endpoint is enabled." : null,
    try(var.private_endpoints.enabled, true) && try(var.private_endpoints.targets.key_vault, true) && try(var.private_endpoints.private_dns_zone_ids.key_vault, null) == null ? "private_endpoints.private_dns_zone_ids.key_vault is required when the Key Vault private endpoint is enabled." : null,
    try(var.private_endpoints.enabled, true) && try(var.private_endpoints.targets.storage_blob, true) && try(var.private_endpoints.private_dns_zone_ids.storage_blob, null) == null ? "private_endpoints.private_dns_zone_ids.storage_blob is required when the Storage blob private endpoint is enabled." : null,
    try(var.private_endpoints.enabled, true) && try(var.private_endpoints.targets.storage_queue, true) && try(var.private_endpoints.private_dns_zone_ids.storage_queue, null) == null ? "private_endpoints.private_dns_zone_ids.storage_queue is required when the Storage queue private endpoint is enabled." : null,
    try(var.private_endpoints.enabled, true) && try(var.private_endpoints.targets.storage_file, false) && try(var.private_endpoints.private_dns_zone_ids.storage_file, null) == null ? "private_endpoints.private_dns_zone_ids.storage_file is required when the Storage file private endpoint is enabled." : null,

    try(var.diagnostics.enabled, true) && try(var.diagnostics.log_analytics_workspace_id, null) == null ? "diagnostics.log_analytics_workspace_id is required when diagnostics.enabled is true." : null,
    try(var.alerts.enabled, true) && try(var.alerts.action_group_id, null) == null ? "alerts.action_group_id is required when alerts.enabled is true." : null,
    lower(var.environment) == "prod" && !try(var.private_endpoints.enabled, true) ? "Production Function App pattern deployments require private_endpoints.enabled=true unless an approved exception is modeled outside this pattern." : null,
    lower(var.environment) == "prod" && !try(var.diagnostics.enabled, true) ? "Production Function App pattern deployments require diagnostics.enabled=true unless an approved exception is modeled outside this pattern." : null,
    lower(var.environment) == "prod" && !try(var.alerts.enabled, true) ? "Production Function App pattern deployments require alerts.enabled=true unless an approved exception is modeled outside this pattern." : null,
    lower(var.environment) == "prod" && try(var.network.app_service_integration_subnet_id, null) == null ? "Production Function App pattern deployments require network.app_service_integration_subnet_id." : null,
  ])

  create_resource_group       = lower(var.resource_group.mode) == "create"
  create_identity             = lower(var.identity.mode) == "create"
  create_app_service_plan     = lower(var.app_service_plan.mode) == "create"
  create_storage_account      = lower(var.storage_account.mode) == "create"
  create_key_vault            = lower(var.key_vault.mode) == "create"
  create_application_insights = lower(var.application_insights.mode) == "create"
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

locals {
  resource_group_name = local.create_resource_group ? module.resource_group[0].name : var.resource_group.existing.name
  resource_group_id   = local.create_resource_group ? module.resource_group[0].id : try(var.resource_group.existing.id, null)
}

module "identity" {
  source = "../../modules/user-assigned-identity"
  count  = local.create_identity ? 1 : 0

  name                = try(var.identity.create.name, null)
  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = module.tags.tags
}

locals {
  identity_id           = local.create_identity ? module.identity[0].id : var.identity.existing.id
  identity_principal_id = local.create_identity ? module.identity[0].principal_id : var.identity.existing.principal_id
  identity_client_id    = local.create_identity ? module.identity[0].client_id : try(var.identity.existing.client_id, null)
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

locals {
  app_service_plan_id = local.create_app_service_plan ? module.app_service_plan[0].id : var.app_service_plan.existing.id
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

locals {
  storage_account_id   = local.create_storage_account ? module.storage_account[0].id : var.storage_account.existing.id
  storage_account_name = local.create_storage_account ? module.storage_account[0].name : var.storage_account.existing.name
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

locals {
  key_vault_id  = local.create_key_vault ? module.key_vault[0].id : var.key_vault.existing.id
  key_vault_uri = local.create_key_vault ? module.key_vault[0].vault_uri : var.key_vault.existing.vault_uri
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

locals {
  application_insights_id                = local.create_application_insights ? module.application_insights[0].id : var.application_insights.existing.id
  application_insights_connection_string = local.create_application_insights ? module.application_insights[0].connection_string : var.application_insights.existing.connection_string

  platform_app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = local.application_insights_connection_string
    KEY_VAULT_URI                         = local.key_vault_uri
    STORAGE_ACCOUNT_NAME                  = local.storage_account_name
    AzureWebJobsStorage__accountName      = local.storage_account_name
  }
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

locals {
  private_endpoint_candidates = {
    function_app = {
      enabled           = try(var.private_endpoints.targets.function_app, true)
      name              = "${var.function_app.name}-pe"
      target_id         = module.function_app.id
      subresource_names = ["sites"]
      private_dns_zone_ids = compact([
        try(var.private_endpoints.private_dns_zone_ids.app_service, null)
      ])
    }
    key_vault = {
      enabled           = try(var.private_endpoints.targets.key_vault, true)
      name              = "${var.application.code}-${var.environment}-kv-pe"
      target_id         = local.key_vault_id
      subresource_names = ["vault"]
      private_dns_zone_ids = compact([
        try(var.private_endpoints.private_dns_zone_ids.key_vault, null)
      ])
    }
    storage_blob = {
      enabled           = try(var.private_endpoints.targets.storage_blob, true)
      name              = "${var.application.code}-${var.environment}-st-blob-pe"
      target_id         = local.storage_account_id
      subresource_names = ["blob"]
      private_dns_zone_ids = compact([
        try(var.private_endpoints.private_dns_zone_ids.storage_blob, null)
      ])
    }
    storage_queue = {
      enabled           = try(var.private_endpoints.targets.storage_queue, true)
      name              = "${var.application.code}-${var.environment}-st-queue-pe"
      target_id         = local.storage_account_id
      subresource_names = ["queue"]
      private_dns_zone_ids = compact([
        try(var.private_endpoints.private_dns_zone_ids.storage_queue, null)
      ])
    }
    storage_file = {
      enabled           = try(var.private_endpoints.targets.storage_file, false)
      name              = "${var.application.code}-${var.environment}-st-file-pe"
      target_id         = local.storage_account_id
      subresource_names = ["file"]
      private_dns_zone_ids = compact([
        try(var.private_endpoints.private_dns_zone_ids.storage_file, null)
      ])
    }
  }

  private_endpoint_targets = try(var.private_endpoints.enabled, true) ? {
    for key, endpoint in local.private_endpoint_candidates : key => endpoint
    if endpoint.enabled
  } : {}
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

locals {
  diagnostic_targets = {
    key_vault            = local.key_vault_id
    storage_account      = local.storage_account_id
    function_app         = module.function_app.id
    application_insights = local.application_insights_id
  }
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
