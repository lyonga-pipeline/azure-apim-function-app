terraform {
  required_version = ">= 1.11.4, < 2.0.0"
  required_providers {
    azapi = { source = "Azure/azapi", version = "~> 2.4.0" }
    tfe   = { source = "hashicorp/tfe", version = ">= 0.80.0, < 1.0.0" }
  }
}
