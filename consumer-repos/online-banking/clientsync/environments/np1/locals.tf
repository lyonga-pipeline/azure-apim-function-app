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

  function_app = merge(var.function_app, {
    infrastructure_app_settings = merge(
      {
        COMPEER_APPLICATION = var.application.code
        COMPEER_ENVIRONMENT = var.environment
      },
      try(var.function_app.infrastructure_app_settings, {}),
    )
  })

  key_vault = merge(var.key_vault, {
    secrets = var.key_vault_secrets
  })
}
