terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0, < 5.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.47.0, < 4.0.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.0.0, < 6.0.0"
    }
  }
}
