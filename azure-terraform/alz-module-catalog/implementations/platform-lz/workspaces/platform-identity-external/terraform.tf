terraform {
  required_version = ">= 1.11.4, < 2.0.0"
  required_providers { azurerm = { source = "hashicorp/azurerm", version = "~> 4.81.0" } }
}
provider "azurerm" {
  features {
    key_vault { purge_soft_delete_on_destroy = false }
    recovery_service {
      vm_backup_stop_protection_and_retain_data_on_destroy = true
      purge_protected_items_from_vault_on_destroy          = false
    }
  }
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
}
