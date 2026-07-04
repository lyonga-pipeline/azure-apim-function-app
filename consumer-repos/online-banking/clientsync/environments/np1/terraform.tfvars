subscription_id = "22222222-2222-2222-2222-222222222222"
tenant_id       = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
location        = "eastus2"
environment     = "np1"

allow_dedicated_app_service_plan = false

application = {
  code                = "clientsync"
  name                = "ClientSync"
  business_owner      = "Digital Banking"
  cost_center         = "CC-1001"
  data_classification = "confidential"
  compliance_boundary = "finserv"
  source_repo         = "ado://Compeer/online-banking"
  terraform_workspace = "lz-workload-clientsync-np1"
  recovery_tier       = "standard"
  additional_tags = {
    deployment_model = "function-app-composition-pattern"
    environment_type = "nonprod"
    pattern_pilot    = "function-app"
    pilot_workload   = "true"
  }
}

resource_group = {
  mode = "create"
  create = {
    name = "rg-clientsync-np1-app"
  }
}

identity = {
  mode = "create"
  create = {
    name = "id-clientsync-np1-app"
  }
}

app_service_plan = {
  mode = "create"
  create = {
    name                   = "asp-clientsync-np1-001"
    os_type                = "Windows"
    sku_name               = "Y1"
    worker_count           = null
    zone_balancing_enabled = null
  }
}

storage_account = {
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
    name                       = "kv-clientsync-np1-001"
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
}

key_vault_secrets = {}

application_insights = {
  mode = "create"
  create = {
    name                          = "appi-clientsync-np1-001"
    application_type              = "web"
    local_authentication_disabled = true
    retention_in_days             = 90
  }
}

function_app = {
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

network = {
  app_service_integration_subnet_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-clientsync-np1-network/providers/Microsoft.Network/virtualNetworks/vnet-clientsync-np1/subnets/app_integration"
}

private_endpoints = {
  enabled   = true
  subnet_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-clientsync-np1-network/providers/Microsoft.Network/virtualNetworks/vnet-clientsync-np1/subnets/private_endpoints"
  targets = {
    function_app  = true
    key_vault     = true
    storage_blob  = true
    storage_queue = true
    storage_file  = true
  }
  private_dns_zone_ids = {
    app_service   = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-lz-platform-connectivity-np/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net"
    key_vault     = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-lz-platform-connectivity-np/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    storage_blob  = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-lz-platform-connectivity-np/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    storage_queue = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-lz-platform-connectivity-np/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net"
    storage_file  = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-lz-platform-connectivity-np/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"
  }
}

diagnostics = {
  enabled                    = true
  log_analytics_workspace_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-lz-platform-management-np/providers/Microsoft.OperationalInsights/workspaces/law-lz-platform-np"
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
  action_group_id    = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-lz-platform-management-np/providers/Microsoft.Insights/actionGroups/ag-lz-cloudops-np"
  severity           = 3
  frequency          = "PT5M"
  window_size        = "PT5M"
  http_5xx_threshold = 10
}
