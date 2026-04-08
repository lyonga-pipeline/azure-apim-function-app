module "tags" {
  source              = "../../../../modules/platform-tags"
  environment         = var.environment
  application         = var.application
  created_by          = var.created_by
  business_owner      = var.business_owner
  source_repo         = var.source_repo
  terraform_workspace = var.terraform_workspace
  recovery_tier       = var.recovery_tier
  cost_center         = var.cost_center
  compliance_boundary = var.compliance_boundary
  creation_date_utc   = var.creation_date_utc
  last_modified_utc   = var.last_modified_utc
  additional_tags     = var.additional_tags
}

module "resource_group" {
  source   = "../../../../modules/resource_group"
  name     = var.workload_resource_group_name
  location = var.location
  tags     = module.tags.tags
}

resource "terraform_data" "demo_windows_vm_password_guard" {
  count = local.demo_windows_vm_enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.demo_windows_vm_password_valid
      error_message = "demo_windows_vm_admin_password is required when enable_demo_windows_vm is true and must be at least 14 characters with upper, lower, numeric, and special characters. Update the DEMO_WINDOWS_VM_ADMIN_PASSWORD secret and rerun."
    }
  }
}

module "spoke_network" {
  source              = "../../../../modules/vnet-spoke"
  name                = var.spoke_vnet_name
  resource_group_name = module.resource_group.name
  location            = var.location
  address_space       = var.spoke_address_space
  subnets             = local.spoke_subnets
  tags                = module.tags.tags
}

module "demo_windows_vm" {
  count                         = local.demo_windows_vm_enabled && local.demo_windows_vm_password_valid ? 1 : 0
  source                        = "../../../../modules/vm_windows"
  name                          = coalesce(var.demo_windows_vm_name, "vm-${var.environment}-${var.application}")
  resource_group_name           = module.resource_group.name
  location                      = var.location
  subnet_id                     = module.spoke_network.subnet_ids[var.demo_windows_vm_subnet_key]
  admin_username                = var.demo_windows_vm_admin_username
  admin_password                = var.demo_windows_vm_admin_password
  vm_size                       = var.demo_windows_vm_size
  identity_type                 = "SystemAssigned"
  os_disk_storage_account_type  = var.demo_windows_vm_os_disk_storage_account_type
  enable_accelerated_networking = false
  encryption_at_host_enabled    = true
  allow_extension_operations    = true
  tags                          = module.tags.tags
  depends_on                    = [terraform_data.demo_windows_vm_password_guard]
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_links" {
  provider              = azurerm.platform
  for_each              = local.connectivity_outputs.private_dns_zone_names
  name                  = "link-${var.environment}-${var.application}-${each.key}"
  resource_group_name   = local.connectivity_outputs.resource_group_name
  private_dns_zone_name = each.value
  virtual_network_id    = module.spoke_network.vnet_id
  tags                  = module.tags.tags
}

module "hub_to_spoke_peering" {
  source = "../../../../modules/vnet-peering"
  providers = {
    azurerm     = azurerm
    azurerm.hub = azurerm.platform
  }
  hub_to_spoke_name       = "peer-hub-to-${var.application}"
  spoke_to_hub_name       = "peer-${var.application}-to-hub"
  hub_vnet_id             = local.connectivity_outputs.hub_vnet_id
  hub_vnet_name           = local.connectivity_outputs.hub_vnet_name
  hub_rg_name             = local.connectivity_outputs.resource_group_name
  spoke_vnet_id           = module.spoke_network.vnet_id
  spoke_vnet_name         = module.spoke_network.vnet_name
  spoke_rg_name           = module.resource_group.name
  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = false
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${var.environment}-${var.application}"
  resource_group_name = module.resource_group.name
  location            = var.location
  application_type    = "web"
  workspace_id        = local.management_outputs.workspace_id
  tags                = module.tags.tags
}

module "app_identity" {
  count               = var.use_shared_identity_services ? 0 : 1
  source              = "../../../../modules/user-assigned-identity"
  name                = "uai-${var.environment}-${var.application}"
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = module.tags.tags
}

# App data storage — accessed exclusively via managed identity and RBAC.
# No shared key: shared_access_key_enabled = false.
#checkov:skip=CKV2_AZURE_33: Storage private endpoints are provisioned through the dedicated private-endpoint module in this stack.
#checkov:skip=CKV2_AZURE_1: This workload storage account is not yet attached to a CMK-backed identity flow.
#checkov:skip=CKV2_AZURE_21: Blob monitoring is handled through Azure Monitor rather than a directly-connected storage-insights graph resource.
module "storage_account" {
  source                        = "../../../../modules/storage"
  name                          = var.storage_account_name
  resource_group_name           = module.resource_group.name
  location                      = var.location
  public_network_access_enabled = false
  shared_access_key_enabled     = false
  containers = {
    app = { access_type = "private" }
  }
  tags = module.tags.tags
}

# Function host storage — separate from app data storage so that the shared key
# required by the Azure Functions runtime does not reach app data access paths.
# The Functions runtime (WEBSITE_CONTENTOVERVNET=1) requires shared key access to
# this account; all other platform access uses Azure AD RBAC.
#checkov:skip=CKV2_AZURE_33: Function host storage private endpoints are provisioned through the dedicated private-endpoint module below.
#checkov:skip=CKV2_AZURE_1: Function host storage uses platform-managed keys; CMK is tracked as a future enhancement.
#checkov:skip=CKV2_AZURE_40: Function App runtime storage requires shared key authorization for compatibility.
#checkov:skip=CKV2_AZURE_21: Blob monitoring is handled through Azure Monitor rather than a directly-connected storage-insights graph resource.
module "function_host_storage" {
  count                         = var.enable_function_app ? 1 : 0
  source                        = "../../../../modules/storage"
  name                          = var.function_host_storage_account_name
  resource_group_name           = module.resource_group.name
  location                      = var.location
  public_network_access_enabled = false
  shared_access_key_enabled     = true
  tags                          = module.tags.tags
}

# Storage insights targets the function host storage (shared_access_key_enabled=true)
# not the app data storage (shared_access_key_enabled=false, no key available).
resource "azurerm_log_analytics_storage_insights" "workload_storage" {
  count                = var.enable_function_app ? 1 : 0
  provider             = azurerm.platform
  name                 = "insights-${var.environment}-${var.application}"
  resource_group_name  = local.management_outputs.resource_group_name
  workspace_id         = local.management_outputs.workspace_id
  storage_account_id   = module.function_host_storage[0].account_id
  storage_account_key  = module.function_host_storage[0].primary_access_key
  blob_container_names = ["*"]
  table_names          = ["*"]
}

#checkov:skip=CKV2_AZURE_32: The Key Vault private endpoint is provisioned separately in this workload stack.
module "key_vault" {
  source                        = "../../../../modules/keyvault"
  name                          = var.key_vault_name
  resource_group_name           = module.resource_group.name
  location                      = var.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.use_shared_identity_services ? "standard" : local.shared_services_cmk_enabled ? "premium" : "standard"
  enable_rbac_authorization     = true
  public_network_access_enabled = false
  network_acls_bypass           = "AzureServices"
  tags                          = module.tags.tags
}

module "shared_services_cmk" {
  count         = !var.use_shared_identity_services && local.shared_services_cmk_enabled ? 1 : 0
  source        = "../../../../modules/keyvault-key"
  name          = "cmk-${var.environment}-${var.application}"
  key_vault_id  = module.key_vault.id
  key_vault_uri = module.key_vault.vault_uri
  key_type      = "RSA-HSM"
  key_size      = 2048
  key_ops       = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}

module "encryption_role_assignments" {
  source      = "../../../../modules/role-assignments"
  assignments = local.encryption_role_assignments
}

module "app_configuration" {
  count                         = var.enable_app_configuration ? 1 : 0
  source                        = "../../../../modules/app-configuration"
  name                          = var.app_configuration_name
  resource_group_name           = module.resource_group.name
  location                      = var.location
  identity_type                 = "UserAssigned"
  identity_ids                  = [local.effective_app_identity.id]
  encryption_key_identifier     = var.enable_app_configuration ? local.shared_services_cmk_key_id : null
  encryption_identity_client_id = var.enable_app_configuration ? local.effective_app_identity.client_id : null
  tags                          = module.tags.tags
  depends_on                    = [module.encryption_role_assignments]
}

module "service_bus" {
  count                            = var.enable_service_bus ? 1 : 0
  source                           = "../../../../modules/service-bus"
  name                             = var.service_bus_name
  resource_group_name              = module.resource_group.name
  location                         = var.location
  identity_type                    = "UserAssigned"
  identity_ids                     = [local.effective_app_identity.id]
  customer_managed_key_id          = var.enable_service_bus ? local.shared_services_cmk_key_id : null
  customer_managed_key_identity_id = var.enable_service_bus ? local.effective_app_identity.id : null
  queues = {
    commands = {}
    events   = {}
  }
  topics = {
    notifications = {}
  }
  tags       = module.tags.tags
  depends_on = [module.encryption_role_assignments]
}

#checkov:skip=CKV2_AZURE_45: The SQL private endpoint is provisioned separately in this workload stack.
module "sql_database" {
  count               = var.enable_sql ? 1 : 0
  source              = "../../../../modules/sql-database"
  name                = var.sql_server_name
  resource_group_name = module.resource_group.name
  location            = var.location
  azuread_administrator = {
    login_username = var.sql_aad_admin_login
    object_id      = var.sql_aad_admin_object_id
  }
  databases = var.sql_databases
  # Auditing uses Log Analytics (log_monitoring_enabled path) — no storage key in state.
  # The legacy storage-key auditing resources in the sql-database module are inactive
  # because extended_auditing_storage_account_access_key and
  # security_alert_storage_account_access_key are intentionally omitted here.
  extended_auditing_policy_enabled = true
  security_alert_policy_enabled    = true
  security_alert_email_addresses   = compact([var.publisher_email])
  tags                             = module.tags.tags
}

module "container_registry" {
  count                         = var.enable_container_registry ? 1 : 0
  source                        = "../../../../modules/container_registry"
  name                          = var.container_registry_name
  resource_group_name           = module.resource_group.name
  location                      = var.location
  public_network_access_enabled = false
  georeplication_locations      = var.container_registry_replica_locations
  tags                          = module.tags.tags
}

module "function_app" {
  count                                  = var.enable_function_app ? 1 : 0
  source                                 = "../../../../modules/function_app"
  name                                   = var.function_app_name
  resource_group_name                    = module.resource_group.name
  location                               = var.location
  app_service_plan_sku                   = var.service_plan_sku
  storage_account_name                   = module.function_host_storage[0].name
  storage_account_access_key             = module.function_host_storage[0].primary_access_key
  application_insights_connection_string = azurerm_application_insights.this.connection_string
  virtual_network_subnet_id              = module.spoke_network.subnet_ids["integration"]
  public_network_access_enabled          = var.function_public_network_access_enabled
  identity_type                          = "UserAssigned"
  identity_ids                           = [local.effective_app_identity.id]
  app_settings = merge({
    WEBSITE_RUN_FROM_PACKAGE = "1"
    WEBSITE_CONTENTOVERVNET  = "1"
    KEY_VAULT_URI            = module.key_vault.vault_uri
    AZURE_CLIENT_ID          = local.effective_app_identity.client_id
    }, var.function_app_settings, var.enable_service_bus ? {
    SERVICEBUS_NAMESPACE = module.service_bus[0].name
    } : {}, var.enable_app_configuration ? {
    APP_CONFIGURATION_ENDPOINT = module.app_configuration[0].endpoint
  } : {})
  tags = module.tags.tags
}

module "storage_private_endpoints" {
  for_each             = local.storage_private_endpoint_targets
  source               = "../../../../modules/private-endpoint"
  name                 = "pe-${each.key}-${var.environment}-${var.application}"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.spoke_network.subnet_ids["private-endpoints"]
  target_resource_id   = module.storage_account.account_id
  subresource_names    = each.value.subresource_names
  private_dns_zone_ids = [local.connectivity_outputs.private_dns_zone_ids[each.value.dns_key]]
  tags                 = module.tags.tags
}

module "function_host_storage_private_endpoints" {
  for_each             = local.function_host_storage_private_endpoint_targets
  source               = "../../../../modules/private-endpoint"
  name                 = "pe-fhst-${each.key}-${var.environment}-${var.application}"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.spoke_network.subnet_ids["private-endpoints"]
  target_resource_id   = module.function_host_storage[0].account_id
  subresource_names    = each.value.subresource_names
  private_dns_zone_ids = [local.connectivity_outputs.private_dns_zone_ids[each.value.dns_key]]
  tags                 = module.tags.tags
}

module "key_vault_private_endpoint" {
  source               = "../../../../modules/private-endpoint"
  name                 = "pe-kv-${var.environment}-${var.application}"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.spoke_network.subnet_ids["private-endpoints"]
  target_resource_id   = module.key_vault.id
  subresource_names    = ["vault"]
  private_dns_zone_ids = [local.connectivity_outputs.private_dns_zone_ids["keyvault"]]
  tags                 = module.tags.tags
}

module "app_configuration_private_endpoint" {
  count                = var.enable_app_configuration ? 1 : 0
  source               = "../../../../modules/private-endpoint"
  name                 = "pe-appconfig-${var.environment}-${var.application}"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.spoke_network.subnet_ids["private-endpoints"]
  target_resource_id   = var.enable_app_configuration ? module.app_configuration[0].id : null
  subresource_names    = ["configurationStores"]
  private_dns_zone_ids = var.enable_app_configuration ? [local.connectivity_outputs.private_dns_zone_ids["appconfig"]] : []
  tags                 = module.tags.tags
}

module "service_bus_private_endpoint" {
  count                = var.enable_service_bus ? 1 : 0
  source               = "../../../../modules/private-endpoint"
  name                 = "pe-sb-${var.environment}-${var.application}"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.spoke_network.subnet_ids["private-endpoints"]
  target_resource_id   = var.enable_service_bus ? module.service_bus[0].id : null
  subresource_names    = ["namespace"]
  private_dns_zone_ids = var.enable_service_bus ? [local.connectivity_outputs.private_dns_zone_ids["servicebus"]] : []
  tags                 = module.tags.tags
}

module "sql_private_endpoint" {
  count                = var.enable_sql ? 1 : 0
  source               = "../../../../modules/private-endpoint"
  name                 = "pe-sql-${var.environment}-${var.application}"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.spoke_network.subnet_ids["private-endpoints"]
  target_resource_id   = var.enable_sql ? module.sql_database[0].server_id : null
  subresource_names    = ["sqlServer"]
  private_dns_zone_ids = var.enable_sql ? [local.connectivity_outputs.private_dns_zone_ids["sql"]] : []
  tags                 = module.tags.tags
}

module "function_private_endpoint" {
  count                = var.enable_function_app && var.enable_function_private_endpoint ? 1 : 0
  source               = "../../../../modules/private-endpoint"
  name                 = "pe-fa-${var.environment}-${var.application}"
  resource_group_name  = module.resource_group.name
  location             = var.location
  subnet_id            = module.spoke_network.subnet_ids["private-endpoints"]
  target_resource_id   = var.enable_function_app ? module.function_app[0].id : null
  subresource_names    = ["sites"]
  private_dns_zone_ids = [local.connectivity_outputs.private_dns_zone_ids["websites"]]
  tags                 = module.tags.tags
}

module "role_assignments" {
  source      = "../../../../modules/role-assignments"
  assignments = local.workload_role_assignments
}

module "key_vault_diagnostics" {
  source                     = "../../../../modules/diagnostics-1"
  name                       = "diag-kv-${var.environment}-${var.application}"
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = local.management_outputs.workspace_id
  enabled_logs               = ["AuditEvent"]
  enabled_metrics            = ["AllMetrics"]
}

module "api_management" {
  count                           = var.enable_apim ? 1 : 0
  source                          = "../../../../modules/apim"
  name                            = var.api_management_name
  resource_group_name             = module.resource_group.name
  location                        = var.location
  publisher_name                  = var.publisher_name
  publisher_email                 = var.publisher_email
  public_network_access_enabled   = false
  virtual_network_type            = "Internal"
  subnet_id                       = var.enable_apim ? module.spoke_network.subnet_ids["apim"] : null
  api_name                        = var.api_name
  api_display_name                = var.api_display_name
  api_path                        = var.api_path
  api_spec_path                   = local.api_spec_path
  backend_url                     = var.enable_function_app ? "https://${module.function_app[0].default_hostname}/api/" : null
  function_app_name               = var.enable_function_app ? module.function_app[0].name : null
  function_app_key_lookup_enabled = false
  function_resource_group         = module.resource_group.name
  tags                            = module.tags.tags
}
