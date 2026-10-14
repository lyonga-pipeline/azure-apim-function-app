terraform {
  required_version = ">= 1.7.0, < 2.0.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">= 4.81.0, < 5.0.0" }
    tfe     = { source = "hashicorp/tfe", version = ">= 0.57.0, < 1.0.0" }
    time    = { source = "hashicorp/time", version = ">= 0.9.0, < 1.0.0" }
  }
}
