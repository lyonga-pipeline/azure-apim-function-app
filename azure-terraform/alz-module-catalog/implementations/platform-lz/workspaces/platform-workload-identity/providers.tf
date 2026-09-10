provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}

# App registration + service principal creation. Run identity needs
# Application.ReadWrite.OwnedBy (or Application Administrator) plus User Access
# Administrator wherever SP role assignments are made.
provider "azuread" {}
