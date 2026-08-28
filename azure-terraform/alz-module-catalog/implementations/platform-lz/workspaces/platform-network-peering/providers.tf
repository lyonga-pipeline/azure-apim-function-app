provider "azurerm" {
  alias = "hub"

  features {}
  subscription_id                 = var.hub_subscription_id
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}

provider "azurerm" {
  alias = "spoke"

  features {}
  subscription_id                 = var.spoke_subscription_id
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}

provider "tfe" {}
