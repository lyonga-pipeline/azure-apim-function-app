terraform {
  # Independent root/state; share only the versioned attachment pattern with prod.
  required_version = ">= 1.11.4, < 2.0.0"
  required_providers {
    azapi = { source = "Azure/azapi", version = "= 2.4.0" }
    tfe   = { source = "hashicorp/tfe", version = "= 0.82.0" }
  }
}
