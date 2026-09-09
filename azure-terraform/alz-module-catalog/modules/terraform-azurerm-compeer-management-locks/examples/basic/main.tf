terraform {
  required_version = ">= 1.5, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.42, < 5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "management_locks" {
  source = "../.."

  locks = {
    platform_rg = {
      name       = "platform-rg-cannot-delete"
      scope      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform-prod"
      lock_level = "CanNotDelete"
      notes      = "Protects critical platform resources from accidental deletion."
    }
  }
}

output "management_lock_ids" {
  value = module.management_locks.ids
}
