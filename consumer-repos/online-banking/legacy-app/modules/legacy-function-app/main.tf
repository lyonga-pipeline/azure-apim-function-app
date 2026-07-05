locals {
  tags = merge(
    {
      env          = var.environment
      application  = var.settings.application.code
      bt_owner     = var.settings.application.business_owner
      source_repo  = var.settings.application.source_repo
      tf_workspace = var.settings.application.tf_workspace
      created_by   = "terraform"
    },
    var.settings.tags,
  )
}

resource "azurerm_resource_group" "this" {
  name     = var.settings.names.resource_group
  location = var.location
  tags     = local.tags
}

resource "azurerm_user_assigned_identity" "this" {
  name                = var.settings.names.identity
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags
}

resource "azurerm_service_plan" "this" {
  name                = var.settings.names.app_service_plan
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = try(var.settings.app_service_plan.os_type, "Windows")
  sku_name            = try(var.settings.app_service_plan.sku_name, "Y1")
  tags                = local.tags
}

resource "azurerm_storage_account" "this" {
  name                              = var.settings.names.storage_account
  resource_group_name               = azurerm_resource_group.this.name
  location                          = azurerm_resource_group.this.location
  account_tier                      = "Standard"
  account_replication_type          = try(var.settings.storage_account.account_replication_type, "LRS")
  account_kind                      = "StorageV2"
  access_tier                       = "Hot"
  min_tls_version                   = "TLS1_2"
  shared_access_key_enabled         = try(var.settings.storage_account.shared_access_key_enabled, true)
  public_network_access_enabled     = try(var.settings.storage_account.public_network_access_enabled, true)
  allow_nested_items_to_be_public   = try(var.settings.storage_account.allow_blob_public_access, true)
  infrastructure_encryption_enabled = true
  default_to_oauth_authentication   = false
  tags                              = local.tags

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "this" {
  for_each = try(var.settings.storage_account.containers, [])

  name                  = each.value
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_storage_queue" "this" {
  for_each = try(var.settings.storage_account.queues, [])

  name               = each.value
  storage_account_id = azurerm_storage_account.this.id
}

resource "azurerm_key_vault" "this" {
  name                          = var.settings.names.key_vault
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = try(var.settings.key_vault.sku_name, "standard")
  public_network_access_enabled = try(var.settings.key_vault.public_network_access_enabled, true)
  enable_rbac_authorization     = try(var.settings.key_vault.enable_rbac_authorization, false)
  purge_protection_enabled      = try(var.settings.key_vault.purge_protection_enabled, false)
  soft_delete_retention_days    = try(var.settings.key_vault.soft_delete_retention_days, 7)
  tags                          = local.tags

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }
}

resource "azurerm_application_insights" "this" {
  name                         = var.settings.names.application_insights
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  application_type             = "web"
  local_authentication_enabled = true
  retention_in_days            = 30
  tags                         = local.tags
}

resource "azurerm_windows_function_app" "this" {
  name                                           = var.settings.names.function_app
  resource_group_name                            = azurerm_resource_group.this.name
  location                                       = azurerm_resource_group.this.location
  service_plan_id                                = azurerm_service_plan.this.id
  storage_account_name                           = azurerm_storage_account.this.name
  storage_account_access_key                     = azurerm_storage_account.this.primary_access_key
  functions_extension_version                    = "~4"
  public_network_access_enabled                  = true
  https_only                                     = false
  ftp_publish_basic_authentication_enabled       = true
  webdeploy_publish_basic_authentication_enabled = true
  key_vault_reference_identity_id                = azurerm_user_assigned_identity.this.id
  tags                                           = local.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  site_config {
    always_on                              = false
    application_insights_connection_string = azurerm_application_insights.this.connection_string
    http2_enabled                          = false
    minimum_tls_version                    = "1.0"
    scm_minimum_tls_version                = "1.0"
    ftps_state                             = "AllAllowed"

    application_stack {
      dotnet_version              = try(var.settings.function_app.dotnet_version, "v8.0")
      use_dotnet_isolated_runtime = true
    }
  }

  app_settings = merge(
    {
      LEGACY_MODULE_STYLE                   = "single-module"
      APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.this.connection_string
      KEY_VAULT_URI                         = azurerm_key_vault.this.vault_uri
      STORAGE_ACCOUNT_NAME                  = azurerm_storage_account.this.name
    },
    try(var.settings.function_app.runtime_app_settings, {}),
  )
}

data "azurerm_client_config" "current" {}
