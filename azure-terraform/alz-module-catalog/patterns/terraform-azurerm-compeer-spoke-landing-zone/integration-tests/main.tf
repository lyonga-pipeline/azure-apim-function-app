data "azurerm_client_config" "current" {}

locals {
  # Naming permits letters-only appcodes. Include the subscription in the unique test namespace.
  appcode = "it${join("", [for character in split("", substr(md5("${var.test_subscription_id}:${var.run_id}"), 0, 7)) : lookup({ "0" = "g", "1" = "h", "2" = "i", "3" = "j", "4" = "k", "5" = "l", "6" = "m", "7" = "n", "8" = "o", "9" = "p" }, character, character)])}"
  tags = {
    test_run = var.run_id
    owner    = "integration-test"
  }
}

resource "terraform_data" "approval" {
  lifecycle {
    precondition {
      condition     = var.allow_live_deployment && data.azurerm_client_config.current.subscription_id == var.test_subscription_id
      error_message = "Live tests require explicit allow_live_deployment=true and a separately authorized isolated test subscription."
    }
  }
}

resource "azurerm_resource_group" "platform" {
  name       = "it-${var.run_id}-platform-rg"
  location   = var.location
  tags       = local.tags
  depends_on = [terraform_data.approval]
}

module "hub" {
  source              = "../../../modules/terraform-azurerm-compeer-virtual-network"
  name                = "it-${var.run_id}-hub-vnet"
  resource_group_name = azurerm_resource_group.platform.name
  location            = var.location
  address_space       = ["10.250.0.0/24"]
  tags                = local.tags
}

module "law" {
  source                          = "../../../modules/terraform-azurerm-compeer-log-analytics"
  log_analytics_workspace_name    = "it-${var.run_id}-law"
  resource_group_name             = azurerm_resource_group.platform.name
  location                        = var.location
  log_analytics_sku               = "PerGB2018"
  log_analytics_retention_in_days = 90
  log_analytics_daily_quota_gb    = -1
  local_authentication_disabled   = true
  tags                            = local.tags
}

resource "azurerm_private_dns_zone" "vault" {
  count               = var.enable_vault_test ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.platform.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone" "blob" {
  count               = var.enable_blob_storage_test ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.platform.name
  tags                = local.tags
}

module "spoke" {
  source = "./.."
  providers = {
    azurerm     = azurerm
    azurerm.dns = azurerm
  }
  subscription_id = var.test_subscription_id
  tenant_id       = data.azurerm_client_config.current.tenant_id
  location        = var.location
  environment     = "dev"
  appcode         = local.appcode
  address_space   = ["10.251.0.0/20"]
  subnets = {
    application       = { address_prefixes = ["10.251.0.0/24"] }
    private_endpoints = { address_prefixes = ["10.251.1.0/27"] }
  }
  # The fixture validates route configuration, not a working firewall. No NVA is created.
  egress_next_hop_ip            = "10.250.0.4"
  allow_azure_provided_dns      = true
  private_endpoint_client_cidrs = var.private_endpoint_client_cidrs
  key_vault                     = { enabled = var.enable_vault_test }
  monitoring = {
    enabled                     = var.enable_optional_operations_test
    create_application_insights = var.enable_optional_operations_test
    alerts_enabled              = var.enable_optional_operations_test
  }
  operations = {
    create_action_group = var.enable_optional_operations_test
    notification_emails = var.enable_optional_operations_test ? compact([var.notification_email]) : []
  }
  storage_accounts = { for key in ["data"] : key => {} if var.enable_blob_storage_test }
  workload_tags = {
    application         = "spoke-integration"
    owner               = "integration-test"
    source_repo         = "ado://Compeer/alz-module-catalog"
    created_on          = var.created_on
    criticality_tier    = "tier-3"
    data_classification = "internal"
    lifecycle_state     = "temporary"
    cost_center         = var.cost_center
    gl_category         = "cloud-infrastructure"
    dr_tier             = "none"
    additional_tags     = { test_run = var.run_id }
  }
  platform = {
    management_contract_version      = "0.1.0"
    connectivity_contract_version    = "0.1.0"
    hub_virtual_network_id           = module.hub.id
    hub_address_space                = module.hub.address_space
    log_analytics_workspace_id       = module.law.id
    key_vault_private_dns_zone_id    = try(azurerm_private_dns_zone.vault[0].id, null)
    storage_blob_private_dns_zone_id = try(azurerm_private_dns_zone.blob[0].id, null)
  }
}

module "attachment" {
  source = "../../terraform-azurerm-compeer-network-peering"
  providers = {
    azurerm.hub   = azurerm
    azurerm.spoke = azurerm
    azurerm.dns   = azurerm
  }
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  hub_subscription_id           = var.test_subscription_id
  spoke_subscription_id         = var.test_subscription_id
  private_dns_subscription_id   = var.test_subscription_id
  hub_virtual_network_id        = module.spoke.attachment_contract.hub_virtual_network_id
  spoke_virtual_network_id      = module.spoke.attachment_contract.spoke_virtual_network_id
  use_tfe_outputs               = false
  use_spoke_attachment_contract = true
  spoke_attachment_contract     = module.spoke.attachment_contract
  tags                          = local.tags
}

resource "azurerm_role_assignment" "probe_operator" {
  count                            = var.enable_secret_probe_operator && var.enable_vault_test ? 1 : 0
  scope                            = module.spoke.key_vault.id
  principal_id                     = data.azurerm_client_config.current.object_id
  principal_type                   = var.runner_principal_type
  role_definition_name             = "Key Vault Secrets Officer"
  skip_service_principal_aad_check = var.runner_principal_type == "ServicePrincipal"
}

output "spoke" {
  value = {
    contract_version           = module.spoke.contract_version
    context                    = module.spoke.context
    resource_group_names       = module.spoke.resource_group_names
    resource_group_ids         = module.spoke.resource_group_ids
    log_analytics_workspace_id = module.spoke.log_analytics_workspace_id
    mandatory_tag_keys         = module.spoke.mandatory_tag_keys
    spoke_virtual_network_id   = module.spoke.spoke_virtual_network_id
    subnet_ids                 = module.spoke.subnet_ids
    key_vault                  = module.spoke.key_vault
    workload_identity          = module.spoke.workload_identity
    attachment_contract        = module.spoke.attachment_contract
    diagnostic_ownership       = module.spoke.diagnostic_ownership
    security_baseline          = module.spoke.security_baseline
    environment_profile        = module.spoke.environment_profile
    application_services       = module.spoke.application_services
  }
}
