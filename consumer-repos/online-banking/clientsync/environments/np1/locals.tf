locals {
  app_service_plan_smoke_defaults = {
    mode = "create"
    create = {
      name                   = "asp-clientsync-np1-001"
      os_type                = "Windows"
      sku_name               = "Y1"
      worker_count           = null
      zone_balancing_enabled = null
    }
  }

  app_service_plan_requested = merge(local.app_service_plan_smoke_defaults, var.app_service_plan, {
    create = merge(local.app_service_plan_smoke_defaults.create, try(var.app_service_plan.create, {}))
  })

  app_service_plan = var.allow_dedicated_app_service_plan ? local.app_service_plan_requested : merge(local.app_service_plan_requested, {
    create = merge(local.app_service_plan_requested.create, {
      sku_name               = "Y1"
      worker_count           = null
      zone_balancing_enabled = null
    })
  })

  storage_account_defaults = {
    mode = "create"
    create = {
      name                          = "stclientsyncnp1001"
      account_replication_type      = "LRS"
      shared_access_key_enabled     = false
      public_network_access_enabled = false
      network_rules = {
        default_action = "Deny"
        bypass         = ["AzureServices"]
      }
      blob_properties = {
        versioning_enabled              = true
        change_feed_enabled             = true
        delete_retention_days           = 7
        container_delete_retention_days = 7
      }
    }
    containers = {
      payloads = {
        container_access_type = "private"
      }
      deadletter = {
        container_access_type = "private"
      }
    }
    queues = {
      inbound = {}
      poison  = {}
    }
    shares = {}
  }

  # HCP workspace variables replace whole objects. Merge np1 defaults back in
  # so partial overrides preserve the enterprise storage posture.
  storage_account = merge(local.storage_account_defaults, var.storage_account, {
    create     = merge(local.storage_account_defaults.create, try(var.storage_account.create, {}))
    containers = merge(local.storage_account_defaults.containers, try(var.storage_account.containers, {}))
    queues     = merge(local.storage_account_defaults.queues, try(var.storage_account.queues, {}))
    shares     = merge(local.storage_account_defaults.shares, try(var.storage_account.shares, {}))
  })

  function_app_smoke_defaults = {
    name                              = "func-clientsync-np1-001"
    os_type                           = "Windows"
    functions_extension_version       = "~4"
    always_on                         = false
    health_check_eviction_time_in_min = 10
    health_check_path                 = "/api/health"
    infrastructure_app_settings       = {}
    runtime_app_settings = {
      CLIENTSYNC_MODE = "NP1"
    }
    application_stack = {
      dotnet_version              = "v8.0"
      use_dotnet_isolated_runtime = true
    }
  }

  # HCP workspace object variables replace the full object. Preserve the health
  # check pair whenever only a subset of Function App settings is set.
  function_app_requested = merge(local.function_app_smoke_defaults, var.function_app, {
    health_check_eviction_time_in_min = coalesce(
      try(var.function_app.health_check_eviction_time_in_min, null),
      local.function_app_smoke_defaults.health_check_eviction_time_in_min,
    )
    health_check_path = coalesce(
      try(var.function_app.health_check_path, null),
      local.function_app_smoke_defaults.health_check_path,
    )
    application_stack = merge(
      local.function_app_smoke_defaults.application_stack,
      try(var.function_app.application_stack, {}),
    )
    infrastructure_app_settings = merge(
      {
        COMPEER_APPLICATION = var.application.code
        COMPEER_ENVIRONMENT = var.environment
      },
      try(var.function_app.infrastructure_app_settings, {}),
    )
    runtime_app_settings = merge(
      local.function_app_smoke_defaults.runtime_app_settings,
      try(var.function_app.runtime_app_settings, {}),
    )
  })

  function_app = var.allow_dedicated_app_service_plan ? local.function_app_requested : merge(local.function_app_requested, {
    always_on = false
  })

  key_vault = merge(var.key_vault, {
    secrets = var.key_vault_secrets
  })

  platform_outputs_enabled = try(var.platform_outputs.enabled, false)

  platform_management_outputs = merge(
    try(data.tfe_outputs.platform_management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.platform_management[0].values, {}),
  )
  platform_connectivity_outputs = merge(
    try(data.tfe_outputs.platform_connectivity[0].nonsensitive_values, {}),
    try(data.tfe_outputs.platform_connectivity[0].values, {}),
  )
  workload_spoke_outputs = merge(
    try(data.tfe_outputs.workload_spoke[0].nonsensitive_values, {}),
    try(data.tfe_outputs.workload_spoke[0].values, {}),
  )

  platform_private_dns_zone_keys = {
    app_service   = coalesce(try(var.platform_outputs.private_dns_zone_keys.app_service, null), "app_service")
    key_vault     = coalesce(try(var.platform_outputs.private_dns_zone_keys.key_vault, null), "key_vault")
    storage_blob  = coalesce(try(var.platform_outputs.private_dns_zone_keys.storage_blob, null), "storage_blob")
    storage_queue = coalesce(try(var.platform_outputs.private_dns_zone_keys.storage_queue, null), "storage_queue")
    storage_file  = coalesce(try(var.platform_outputs.private_dns_zone_keys.storage_file, null), "storage_file")
  }

  app_service_integration_subnet_candidates = [
    for value in [
      try(var.network.app_service_integration_subnet_id, null),
      try(local.workload_spoke_outputs.app_service_integration_subnet_id, null),
      try(local.workload_spoke_outputs.subnet_ids[var.platform_outputs.app_integration_subnet_key], null),
    ] : value if value != null && value != ""
  ]
  private_endpoint_subnet_candidates = [
    for value in [
      try(var.private_endpoints.subnet_id, null),
      try(local.workload_spoke_outputs.private_endpoint_subnet_id, null),
      try(local.workload_spoke_outputs.subnet_ids[var.platform_outputs.private_endpoint_subnet_key], null),
    ] : value if value != null && value != ""
  ]

  app_service_integration_subnet_id = try(local.app_service_integration_subnet_candidates[0], null)
  private_endpoint_subnet_id        = try(local.private_endpoint_subnet_candidates[0], null)

  private_dns_zone_id_sources = {
    app_service = [
      try(var.private_endpoints.private_dns_zone_ids.app_service, null),
      try(local.platform_connectivity_outputs.app_service_private_dns_zone_id, null),
      try(local.platform_connectivity_outputs.private_dns_zone_ids[local.platform_private_dns_zone_keys.app_service], null),
    ]
    key_vault = [
      try(var.private_endpoints.private_dns_zone_ids.key_vault, null),
      try(local.platform_connectivity_outputs.key_vault_private_dns_zone_id, null),
      try(local.platform_connectivity_outputs.private_dns_zone_ids[local.platform_private_dns_zone_keys.key_vault], null),
    ]
    storage_blob = [
      try(var.private_endpoints.private_dns_zone_ids.storage_blob, null),
      try(local.platform_connectivity_outputs.storage_blob_private_dns_zone_id, null),
      try(local.platform_connectivity_outputs.private_dns_zone_ids[local.platform_private_dns_zone_keys.storage_blob], null),
    ]
    storage_queue = [
      try(var.private_endpoints.private_dns_zone_ids.storage_queue, null),
      try(local.platform_connectivity_outputs.storage_queue_private_dns_zone_id, null),
      try(local.platform_connectivity_outputs.private_dns_zone_ids[local.platform_private_dns_zone_keys.storage_queue], null),
    ]
    storage_file = [
      try(var.private_endpoints.private_dns_zone_ids.storage_file, null),
      try(local.platform_connectivity_outputs.storage_file_private_dns_zone_id, null),
      try(local.platform_connectivity_outputs.private_dns_zone_ids[local.platform_private_dns_zone_keys.storage_file], null),
    ]
  }

  private_dns_zone_id_candidates = {
    for key, values in local.private_dns_zone_id_sources : key => [
      for value in values : value if value != null && value != ""
    ]
  }
  resolved_private_dns_zone_ids = {
    for key, values in local.private_dns_zone_id_candidates : key => try(values[0], null)
  }
  private_dns_zone_ids_for_merge = {
    for key, value in local.resolved_private_dns_zone_ids : key => value
    if value != null && value != ""
  }
  private_endpoint_effective_subnet_id = local.platform_outputs_enabled ? local.private_endpoint_subnet_id : try(var.private_endpoints.subnet_id, null)
  private_endpoint_effective_dns_zone_ids = local.platform_outputs_enabled ? tomap(merge(
    try(var.private_endpoints.private_dns_zone_ids, {}),
    local.private_dns_zone_ids_for_merge,
  )) : tomap(try(var.private_endpoints.private_dns_zone_ids, {}))

  log_analytics_workspace_id_candidates = [
    for value in [
      try(var.diagnostics.log_analytics_workspace_id, null),
      try(local.platform_management_outputs.log_analytics_workspace_id, null),
    ] : value if value != null && value != ""
  ]
  action_group_id_candidates = [
    for value in [
      try(var.alerts.action_group_id, null),
      try(local.platform_management_outputs.action_group_id, null),
    ] : value if value != null && value != ""
  ]

  log_analytics_workspace_id = try(local.log_analytics_workspace_id_candidates[0], null)
  action_group_id            = try(local.action_group_id_candidates[0], null)

  network = merge(
    var.network,
    local.platform_outputs_enabled && local.app_service_integration_subnet_id != null ? {
      app_service_integration_subnet_id = local.app_service_integration_subnet_id
    } : {},
  )

  private_endpoints = merge(
    var.private_endpoints,
    {
      subnet_id            = local.private_endpoint_effective_subnet_id
      private_dns_zone_ids = local.private_endpoint_effective_dns_zone_ids
    },
  )

  diagnostics = merge(
    var.diagnostics,
    local.platform_outputs_enabled && try(var.platform_outputs.use_platform_log_analytics, true) && local.log_analytics_workspace_id != null ? {
      log_analytics_workspace_id = local.log_analytics_workspace_id
    } : {},
  )

  alerts = merge(
    var.alerts,
    local.platform_outputs_enabled && local.action_group_id != null ? {
      action_group_id = local.action_group_id
    } : {},
  )

  platform_output_errors = nonsensitive(compact([
    local.platform_outputs_enabled && local.app_service_integration_subnet_id == null ? "platform_outputs could not resolve the app service integration subnet. Apply '${var.platform_outputs.workload_spoke_workspace}' after it exposes app_service_integration_subnet_id/subnet_ids, confirm TFE_TOKEN can read it, or set network.app_service_integration_subnet_id explicitly." : null,
    local.platform_outputs_enabled && try(var.private_endpoints.enabled, false) && local.private_endpoint_subnet_id == null ? "platform_outputs could not resolve the private endpoint subnet. Apply '${var.platform_outputs.workload_spoke_workspace}' after it exposes private_endpoint_subnet_id/subnet_ids, confirm TFE_TOKEN can read it, or set private_endpoints.subnet_id explicitly." : null,
    local.platform_outputs_enabled && try(var.private_endpoints.enabled, false) && try(var.private_endpoints.targets.function_app, true) && local.resolved_private_dns_zone_ids.app_service == null ? "platform_outputs could not resolve the App Service private DNS zone ID from '${var.platform_outputs.platform_connectivity_workspace}'." : null,
    local.platform_outputs_enabled && try(var.private_endpoints.enabled, false) && try(var.private_endpoints.targets.key_vault, true) && local.resolved_private_dns_zone_ids.key_vault == null ? "platform_outputs could not resolve the Key Vault private DNS zone ID from '${var.platform_outputs.platform_connectivity_workspace}'." : null,
    local.platform_outputs_enabled && try(var.private_endpoints.enabled, false) && try(var.private_endpoints.targets.storage_blob, true) && local.resolved_private_dns_zone_ids.storage_blob == null ? "platform_outputs could not resolve the Storage Blob private DNS zone ID from '${var.platform_outputs.platform_connectivity_workspace}'." : null,
    local.platform_outputs_enabled && try(var.private_endpoints.enabled, false) && try(var.private_endpoints.targets.storage_queue, true) && local.resolved_private_dns_zone_ids.storage_queue == null ? "platform_outputs could not resolve the Storage Queue private DNS zone ID from '${var.platform_outputs.platform_connectivity_workspace}'." : null,
    local.platform_outputs_enabled && try(var.private_endpoints.enabled, false) && try(var.private_endpoints.targets.storage_file, false) && local.resolved_private_dns_zone_ids.storage_file == null ? "platform_outputs could not resolve the Storage File private DNS zone ID from '${var.platform_outputs.platform_connectivity_workspace}'." : null,
    local.platform_outputs_enabled && try(var.platform_outputs.use_platform_log_analytics, true) && local.log_analytics_workspace_id == null ? "platform_outputs could not resolve log_analytics_workspace_id from '${var.platform_outputs.platform_management_workspace}'." : null,
    local.platform_outputs_enabled && (try(var.platform_outputs.use_platform_action_group, false) || try(var.alerts.enabled, false)) && local.action_group_id == null ? "platform_outputs could not resolve action_group_id from '${var.platform_outputs.platform_management_workspace}'." : null,
  ]))
}
