terraform {
  required_version = ">= 1.2"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      #version = ">= 3.100.0, < 5.0.0"
      version = ">= 3.11, < 5.0"
    }
  }
}
