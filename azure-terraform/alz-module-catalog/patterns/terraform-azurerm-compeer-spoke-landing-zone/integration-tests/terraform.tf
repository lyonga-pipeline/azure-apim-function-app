terraform {
  required_version = ">= 1.11.4, < 2.0.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">= 4.81.0, < 5.0.0" }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    storage { data_plane_available = false }
  }
  storage_use_azuread             = true
  subscription_id                 = var.test_subscription_id
  resource_provider_registrations = "none"
  resource_providers_to_register  = ["Microsoft.Network", "Microsoft.KeyVault", "Microsoft.ManagedIdentity", "Microsoft.Insights", "Microsoft.OperationalInsights", "Microsoft.Storage"]
}
