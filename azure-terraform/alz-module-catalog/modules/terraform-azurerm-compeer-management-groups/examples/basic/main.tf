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

module "management_groups" {
  source = "../.."

  management_groups = {
    alz = {
      display_name               = "ALZ"
      parent_management_group_id = "/providers/Microsoft.Management/managementGroups/tenant-root"
    }

    platform = {
      display_name = "Platform"
      parent_key   = "alz"
    }

    landing_zones = {
      display_name = "Landing Zones"
      parent_key   = "alz"
    }

    corp = {
      display_name = "Corp"
      parent_key   = "landing_zones"
      subscription_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000"
      ]
    }
  }
}

output "management_group_ids" {
  value = module.management_groups.management_group_ids
}
