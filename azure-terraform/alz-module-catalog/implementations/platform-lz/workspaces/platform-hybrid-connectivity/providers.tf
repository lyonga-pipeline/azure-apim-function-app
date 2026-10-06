provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
  resource_providers_to_register = [
    "Microsoft.Network",
  ]
}

provider "tfe" {}
