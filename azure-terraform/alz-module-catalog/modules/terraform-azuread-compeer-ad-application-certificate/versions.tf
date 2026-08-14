terraform {
  required_version = ">= 1.2"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">=2.30.0, < 3.0.0"
    }
  }
}
