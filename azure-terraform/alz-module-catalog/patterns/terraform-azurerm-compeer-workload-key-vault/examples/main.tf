terraform {
  required_version = ">= 1.11.4, < 2.0.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">= 4.81.0, < 5.0.0" }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy       = false
      purge_soft_deleted_keys_on_destroy = false
      recover_soft_deleted_key_vaults    = true
      recover_soft_deleted_keys          = true
    }
  }
  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}

resource "terraform_data" "approval" {
  lifecycle {
    precondition {
      condition     = !var.enabled || var.deployment_approved
      error_message = "Do not enable the example until the target subscription, existing dependencies, network access and change approval are confirmed."
    }
  }
}

module "vault" {
  source                     = "../"
  count                      = var.enabled ? 1 : 0
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = var.tenant_id
  environment                = var.environment
  appcode                    = var.appcode
  domain                     = var.domain
  name                       = var.name
  sku_name                   = var.sku_name
  private_endpoint_subnet_id = var.private_endpoint_subnet_id
  private_dns_zone_id        = var.private_dns_zone_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  diagnostics                = var.diagnostics
  secret_readers             = var.secret_readers
  secret_officer_group_ids   = var.secret_officer_group_ids
  tags                       = var.tags
  private_endpoints          = var.private_endpoints
  network_access             = var.network_access
  data_access                = var.data_access
  keys                       = var.keys
  monitoring                 = var.monitoring
  timeouts                   = var.timeouts
  depends_on                 = [terraform_data.approval]
}

output "vault" {
  description = "Non-secret workload integration contract; null while the example is disabled."
  value = try({
    id                     = module.vault[0].id
    name                   = module.vault[0].name
    uri                    = module.vault[0].uri
    private_endpoints      = module.vault[0].private_endpoints
    diagnostic_setting_id  = module.vault[0].diagnostic_setting_id
    role_assignment_ids    = module.vault[0].role_assignment_ids
    key_ids                = module.vault[0].key_ids
    key_versionless_ids    = module.vault[0].key_versionless_ids
    metric_alert_ids       = module.vault[0].metric_alert_ids
    security_configuration = module.vault[0].security_configuration
  }, null)
}
