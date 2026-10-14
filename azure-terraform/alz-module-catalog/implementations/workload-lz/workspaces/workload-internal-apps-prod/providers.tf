provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    storage { data_plane_available = false }
    recovery_service {
      vm_backup_stop_protection_and_retain_data_on_destroy = true
      purge_protected_items_from_vault_on_destroy          = false
    }
  }
  storage_use_azuread             = true
  subscription_id                 = coalesce(var.subscription_id, "00000000-0000-0000-0000-000000000000")
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
  resource_providers_to_register  = ["Microsoft.Network", "Microsoft.KeyVault", "Microsoft.ManagedIdentity", "Microsoft.Insights", "Microsoft.Storage", "Microsoft.RecoveryServices", "Microsoft.Consumption"]
}
provider "azurerm" {
  alias = "connectivity"
  features {}
  subscription_id                 = coalesce(var.connectivity_subscription_id, "00000000-0000-0000-0000-000000000000")
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}
provider "azurerm" {
  alias = "dns"
  features {}
  subscription_id                 = coalesce(var.private_dns_subscription_id, var.connectivity_subscription_id, "00000000-0000-0000-0000-000000000000")
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}
provider "tfe" {}
provider "time" {}
