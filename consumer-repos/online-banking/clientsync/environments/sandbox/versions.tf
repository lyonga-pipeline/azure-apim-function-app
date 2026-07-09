terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }

  cloud {
    organization = "lyonga-org"

    workspaces {
      name = "lz-workload-clientsync-sandbox"
    }
  }
}
