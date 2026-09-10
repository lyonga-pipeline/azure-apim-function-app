provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}

# Directory writes (group creation). Auth comes from the same HCP dynamic
# credentials / ARM_* environment as azurerm; the run identity needs directory
# write plus User Access Administrator at the target management-group scope.
provider "azuread" {}
