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

    try(var.diagnostics.enabled, true) && try(var.diagnostics.log_analytics_workspace_id, null) == null && try(var.diagnostics.workspace.create, null) == null ? "diagnostics.log_analytics_workspace_id or diagnostics.workspace.create is required when diagnostics.enabled is true." : null,
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
  create_diagnostics_workspace = (
    try(var.diagnostics.enabled, true) &&
    try(var.diagnostics.log_analytics_workspace_id, null) == null &&
    try(var.diagnostics.workspace.create, null) != null
  )

  resource_group_name = local.create_resource_group ? module.resource_group[0].name : var.resource_group.existing.name
  resource_group_id   = local.create_resource_group ? module.resource_group[0].id : try(var.resource_group.existing.id, null)

  identity_id           = local.create_identity ? module.identity[0].id : var.identity.existing.id
  identity_principal_id = local.create_identity ? module.identity[0].principal_id : var.identity.existing.principal_id
  identity_client_id    = local.create_identity ? module.identity[0].client_id : try(var.identity.existing.client_id, null)

  app_service_plan_id = local.create_app_service_plan ? module.app_service_plan[0].id : var.app_service_plan.existing.id

  storage_account_id   = local.create_storage_account ? module.storage_account[0].id : var.storage_account.existing.id
  storage_account_name = local.create_storage_account ? module.storage_account[0].name : var.storage_account.existing.name

  key_vault_id  = local.create_key_vault ? module.key_vault[0].id : var.key_vault.existing.id
  key_vault_uri = local.create_key_vault ? module.key_vault[0].vault_uri : var.key_vault.existing.vault_uri

  application_insights_id                = local.create_application_insights ? module.application_insights[0].id : var.application_insights.existing.id
  application_insights_connection_string = local.create_application_insights ? module.application_insights[0].connection_string : var.application_insights.existing.connection_string
  diagnostic_log_analytics_workspace_id  = local.create_diagnostics_workspace ? module.diagnostics_log_analytics[0].id : try(var.diagnostics.log_analytics_workspace_id, null)

  platform_app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING = local.application_insights_connection_string
    KEY_VAULT_URI                         = local.key_vault_uri
    STORAGE_ACCOUNT_NAME                  = local.storage_account_name
    AzureWebJobsStorage__accountName      = local.storage_account_name
  }

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

  diagnostic_targets = {
    key_vault            = local.key_vault_id
    storage_account      = local.storage_account_id
    function_app         = module.function_app.id
    application_insights = local.application_insights_id
  }
}
