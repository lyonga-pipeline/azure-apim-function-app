subscription_id = "44444444-4444-4444-4444-444444444444"
tenant_id       = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
location        = "eastus2"
environment     = "prod"

application = {
  code                = "obanking"
  name                = "Online Banking"
  business_owner      = "Digital Banking"
  cost_center         = "CC-1001"
  data_classification = "confidential"
  compliance_boundary = "finserv"
  source_repo         = "ado://Compeer/online-banking"
}

resource_group = {
  name = "rg-online-banking-prod-app"
}

shared = {
  log_analytics_workspace_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/rg-shared-observability-prod/providers/Microsoft.OperationalInsights/workspaces/law-compeer-prod"
  action_group_id            = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/rg-shared-observability-prod/providers/Microsoft.Insights/actionGroups/ag-cloudops-prod"
  subnet_ids = {
    app_integration  = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-prod-shared/subnets/snet-appintegration"
    private_endpoint = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/rg-network-prod/providers/Microsoft.Network/virtualNetworks/vnet-prod-shared/subnets/snet-private-endpoints"
  }
  private_dns_zone_ids = {
    app_service   = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/rg-private-dns-prod/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net"
    key_vault     = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/rg-private-dns-prod/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    storage_blob  = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/rg-private-dns-prod/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    storage_file  = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/rg-private-dns-prod/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"
    storage_queue = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/rg-private-dns-prod/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net"
  }
}

identity = {
  name = "id-online-banking-prod-app"
}

key_vault = {
  name                       = "kv-obanking-prod-001"
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

key_vault_secrets = {}

storage_account = {
  name                     = "stobankingprodcore01"
  account_replication_type = "ZRS"
  containers = {
    app        = {}
    deadletter = {}
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

app_service_plan = {
  name                   = "asp-online-banking-prod-001"
  os_type                = "Windows"
  sku_name               = "P1v3"
  worker_count           = 3
  zone_balancing_enabled = true
}

function_app = {
  name                        = "func-online-banking-prod-001"
  os_type                     = "Windows"
  functions_extension_version = "~4"
  always_on                   = true
  health_check_path           = "/api/health"
  app_settings = {
    ASPNETCORE_ENVIRONMENT = "Production"
    COMPEER_ENVIRONMENT    = "prod"
  }
  application_stack = {
    dotnet_version              = "v8.0"
    use_dotnet_isolated_runtime = true
  }
}

diagnostics = {
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

alerts = {
  http_5xx_threshold = 3
  severity           = 1
  frequency          = "PT1M"
  window_size        = "PT5M"
}

additional_tags = {
  environment_type = "prod"
  deployment_model = "hcp-registry-pinned"
  production_like  = "true"
}
