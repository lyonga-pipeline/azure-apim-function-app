locals {
  storage_account_smoke_defaults = {
    mode = "create"
    create = {
      name                          = "stclientsyncnp1001"
      account_replication_type      = "LRS"
      shared_access_key_enabled     = true
      public_network_access_enabled = true
      network_rules = {
        default_action = "Allow"
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

  # HCP workspace variables replace whole objects. Merge smoke defaults back in
  # so partial overrides do not accidentally disable provider data-plane access.
  storage_account = merge(local.storage_account_smoke_defaults, var.storage_account, {
    create     = merge(local.storage_account_smoke_defaults.create, try(var.storage_account.create, {}))
    containers = merge(local.storage_account_smoke_defaults.containers, try(var.storage_account.containers, {}))
    queues     = merge(local.storage_account_smoke_defaults.queues, try(var.storage_account.queues, {}))
    shares     = merge(local.storage_account_smoke_defaults.shares, try(var.storage_account.shares, {}))
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
  function_app = merge(local.function_app_smoke_defaults, var.function_app, {
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

  key_vault = merge(var.key_vault, {
    secrets = var.key_vault_secrets
  })
}
