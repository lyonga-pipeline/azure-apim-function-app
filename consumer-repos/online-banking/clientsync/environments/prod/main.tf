locals {
  app_code            = "clientsync"
  terraform_workspace = "lz-workload-clientsync-prod"
}

module "clientsync_function_app" {
  source = "../../../../../azure-terraform/patterns/function-app"

  environment = var.environment
  location    = var.location
  tenant_id   = var.tenant_id

  application = {
    code                = local.app_code
    name                = "ClientSync"
    business_owner      = "Digital Banking"
    cost_center         = "CC-1001"
    data_classification = "confidential"
    compliance_boundary = "finserv"
    source_repo         = "ado://Compeer/online-banking"
    terraform_workspace = local.terraform_workspace
    recovery_tier       = "mission-critical"
    additional_tags = merge(
      {
        deployment_model = "function-app-composition-pattern"
        pilot_workload   = "true"
      },
      var.additional_tags,
    )
  }

  resource_group = {
    mode = "create"
    create = {
      name = var.names.resource_group
    }
  }

  identity = {
    mode = "create"
    create = {
      name = var.names.identity
    }
  }

  app_service_plan = {
    mode = "create"
    create = {
      name                   = var.names.app_service_plan
      os_type                = "Windows"
      sku_name               = "P1v3"
      worker_count           = 3
      zone_balancing_enabled = true
    }
  }

  storage_account = {
    mode = "create"
    create = {
      name                     = var.names.storage_account
      account_replication_type = "ZRS"
      blob_properties = {
        versioning_enabled              = true
        change_feed_enabled             = true
        delete_retention_days           = 30
        container_delete_retention_days = 30
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
    shares = {
      appconfig = {
        quota       = 100
        access_tier = "TransactionOptimized"
      }
    }
  }

  key_vault = {
    mode = "create"
    create = {
      name                       = var.names.key_vault
      sku_name                   = "standard"
      soft_delete_retention_days = 90
      purge_protection_enabled   = true
      contacts = {
        cloudops = {
          email = "cloudops@compeer.example"
          name  = "Cloud Operations"
        }
      }
    }
    secrets = var.key_vault_secrets
  }

  application_insights = {
    mode = "create"
    create = {
      name                          = var.names.application_insights
      application_type              = "web"
      local_authentication_disabled = true
      retention_in_days             = 180
    }
  }

  function_app = {
    name                        = var.names.function_app
    os_type                     = "Windows"
    functions_extension_version = "~4"
    always_on                   = true
    health_check_path           = "/api/health"
    infrastructure_app_settings = {
      COMPEER_APPLICATION = "clientsync"
      COMPEER_ENVIRONMENT = var.environment
    }
    runtime_app_settings = var.runtime_app_settings
    application_stack = {
      dotnet_version              = "v8.0"
      use_dotnet_isolated_runtime = true
    }
  }

  network = {
    app_service_integration_subnet_id = var.shared.subnet_ids.app_integration
  }

  private_endpoints = {
    enabled   = true
    subnet_id = var.shared.subnet_ids.private_endpoint
    targets = {
      function_app  = true
      key_vault     = true
      storage_blob  = true
      storage_queue = true
      storage_file  = true
    }
    private_dns_zone_ids = {
      app_service   = var.shared.private_dns_zone_ids.app_service
      key_vault     = var.shared.private_dns_zone_ids.key_vault
      storage_blob  = var.shared.private_dns_zone_ids.storage_blob
      storage_queue = var.shared.private_dns_zone_ids.storage_queue
      storage_file  = var.shared.private_dns_zone_ids.storage_file
    }
  }

  diagnostics = {
    enabled                    = true
    log_analytics_workspace_id = var.shared.log_analytics_workspace_id
    logs = {
      all_logs = {
        category_group = "allLogs"
      }
    }
    metrics = {
      all_metrics = {
        category = "AllMetrics"
        enabled  = true
      }
    }
  }

  role_assignments = {
    enabled    = true
    additional = {}
  }

  alerts = {
    enabled            = true
    action_group_id    = var.shared.action_group_id
    severity           = 2
    frequency          = "PT5M"
    window_size        = "PT5M"
    http_5xx_threshold = 5
  }
}
