terraform {
  required_version = ">= 1.2"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.11, < 5.0"
      #version = ">= 4.19.0, < 5.0"
    }
  }
}
