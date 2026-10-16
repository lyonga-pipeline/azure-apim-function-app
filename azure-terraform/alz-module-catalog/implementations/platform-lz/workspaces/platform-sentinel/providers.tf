# Sentinel content lives on the central Log Analytics workspace, which is in
# the management subscription - so this workspace's subscription_id is the
# management subscription's.
provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}

provider "tfe" {}
