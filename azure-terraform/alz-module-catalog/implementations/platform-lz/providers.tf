provider "azurerm" {
  features {}
  subscription_id                 = var.execution_subscription_id
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}

provider "azurerm" {
  alias = "management"

  features {}
  subscription_id                 = try(var.platform_management.subscription_id, var.execution_subscription_id)
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}

provider "azurerm" {
  alias = "connectivity"

  features {}
  subscription_id                 = try(var.platform_connectivity.subscription_id, var.execution_subscription_id)
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}

provider "azurerm" {
  alias = "identity"

  features {}
  subscription_id                 = try(var.platform_identity.subscription_id, var.execution_subscription_id)
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}

provider "azurerm" {
  alias = "hybrid"

  features {}
  subscription_id                 = try(var.platform_hybrid_connectivity.subscription_id, try(var.platform_connectivity.subscription_id, var.execution_subscription_id))
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}

provider "azurerm" {
  alias = "workload"

  features {}
  subscription_id                 = try(var.workload_spoke.subscription_id, var.execution_subscription_id)
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "cloudflare" {}
