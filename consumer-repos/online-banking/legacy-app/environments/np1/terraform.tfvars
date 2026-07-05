location    = "eastus"
environment = "np1"

legacy_app = {
  application = {
    code           = "legacy-app"
    name           = "Legacy App"
    business_owner = "Digital Banking"
    source_repo    = "ado://Compeer/online-banking"
    tf_workspace   = "lz-workload-legacy-app-np1"
  }

  names = {
    resource_group       = "rg-legacy-app-np1-app"
    identity             = "id-legacy-app-np1-app"
    app_service_plan     = "asp-legacy-app-np1-001"
    storage_account      = "stlegacyappnp1001"
    key_vault            = "kv-legacy-app-np1-001"
    application_insights = "appi-legacy-app-np1-001"
    function_app         = "func-legacy-app-np1-001"
  }

  # Intentionally incomplete tags for policy training. Missing required tags:
  # recovery, cost_center, data_classification, and compliance_boundary.
  tags = {
    migration_wave = "legacy-demo"
    owner_note     = "intentionally-incomplete-for-training"
  }

  app_service_plan = {
    os_type  = "Windows"
    sku_name = "Y1"
  }

  storage_account = {
    account_replication_type      = "LRS"
    shared_access_key_enabled     = true
    public_network_access_enabled = true
    allow_blob_public_access      = true
    containers                    = ["payloads", "deadletter"]
    queues                        = ["inbound", "poison"]
  }

  key_vault = {
    sku_name                      = "standard"
    public_network_access_enabled = true
    rbac_authorization_enabled    = false
    purge_protection_enabled      = false
    soft_delete_retention_days    = 7
  }

  function_app = {
    runtime_app_settings = {
      LEGACY_APP_MODE = "NP1"
    }
    dotnet_version = "v8.0"
  }
}
