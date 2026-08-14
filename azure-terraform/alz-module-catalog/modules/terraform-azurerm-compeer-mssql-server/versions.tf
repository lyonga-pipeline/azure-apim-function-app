terraform {
  required_version = ">= 1.2"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      #version = ">=3.11, < 4.0"
      version = ">=3.11, < 5.0"
    }
  }
}
