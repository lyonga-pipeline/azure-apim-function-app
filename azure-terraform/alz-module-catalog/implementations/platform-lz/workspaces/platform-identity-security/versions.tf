terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0, < 5.0.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.58.0, < 1.0.0"
    }
  }
}
