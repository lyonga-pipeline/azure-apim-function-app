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
  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  storage_use_azuread             = true
  resource_provider_registrations = "none"
  resource_providers_to_register  = ["Microsoft.Network", "Microsoft.KeyVault", "Microsoft.ManagedIdentity", "Microsoft.Insights", "Microsoft.Storage", "Microsoft.RecoveryServices"]
}
provider "azurerm" {
  alias = "dns"
  features {}
  subscription_id                 = var.private_dns_subscription_id
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
}
