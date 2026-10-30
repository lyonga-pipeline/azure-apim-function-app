terraform {
  required_version = ">= 1.11.4, < 2.0.0"
  required_providers {
    tfe = { source = "hashicorp/tfe", version = "~> 0.82.0" }
  }
}
provider "tfe" {}
