terraform {
  required_version = ">= 1.11.4, < 2.0.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.81.0" }
  }
}
variable "subscription_id" { type = string }
provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  resource_provider_registrations = "none"
  storage_use_azuread             = true
}
