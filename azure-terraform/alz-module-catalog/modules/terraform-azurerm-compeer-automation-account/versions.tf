terraform {
  required_version = ">= 1.5, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.42, < 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4, < 3.0"
    }
  }
}
