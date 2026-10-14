terraform {
  required_version = ">= 1.11.4, < 2.0.0"

  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = ">= 4.42.0, < 5.0.0"
      configuration_aliases = [azurerm.hub, azurerm.spoke, azurerm.dns]
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.78"
    }
  }
}
