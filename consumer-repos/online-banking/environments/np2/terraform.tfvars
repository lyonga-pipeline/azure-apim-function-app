subscription_id = "22222222-2222-2222-2222-222222222222"
tenant_id       = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
location        = "eastus2"
environment     = "np2"

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
  name = "rg-online-banking-np2-app"
}

shared = {
  log_analytics_workspace_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-shared-observability-np/providers/Microsoft.OperationalInsights/workspaces/law-compeer-np"
  action_group_id            = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-shared-observability-np/providers/Microsoft.Insights/actionGroups/ag-cloudops-np"
  subnet_ids = {
    app_integration  = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-network-np2/providers/Microsoft.Network/virtualNetworks/vnet-np2-shared/subnets/snet-appintegration"
    private_endpoint = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-network-np2/providers/Microsoft.Network/virtualNetworks/vnet-np2-shared/subnets/snet-private-endpoints"
  }
  private_dns_zone_ids = {
    app_service   = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-private-dns-np/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net"
    key_vault     = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-private-dns-np/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    storage_blob  = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-private-dns-np/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    storage_file  = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-private-dns-np/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"
    storage_queue = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-private-dns-np/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net"
  }
}

identity = {
  name = "id-online-banking-np2-app"
}

key_vault = {
  name                       = "kv-obanking-np2-001"
  sku_name                   = "standard"
  soft_delete_retention_days = 30
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
  name                     = "stobankingnp2core01"
  account_replication_type = "LRS"
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
  name         = "asp-online-banking-np2-001"
  os_type      = "Windows"
  sku_name     = "P1v3"
  worker_count = 1
}

function_app = {
  name                        = "func-online-banking-np2-001"
  os_type                     = "Windows"
  functions_extension_version = "~4"
  always_on                   = true
  health_check_path           = "/api/health"
  app_settings = {
    ASPNETCORE_ENVIRONMENT = "Development"
    COMPEER_ENVIRONMENT    = "np2"
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
  http_5xx_threshold = 10
  severity           = 3
  frequency          = "PT5M"
  window_size        = "PT5M"
}

additional_tags = {
  environment_type = "nonprod"
  deployment_model = "hcp-registry-pinned"
}
