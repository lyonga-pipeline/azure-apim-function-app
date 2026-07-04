location    = "eastus"
environment = "np1"

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

network = {}

private_endpoints = {
  enabled = false
}

diagnostics = {
  enabled = false
}

role_assignments = {
  enabled    = true
  additional = {}
}

alerts = {
  enabled = false
}
