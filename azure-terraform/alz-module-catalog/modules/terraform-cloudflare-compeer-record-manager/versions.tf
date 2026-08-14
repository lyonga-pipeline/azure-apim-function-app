terraform {
  required_version = ">= 0.13.1"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.11.0"
    }
  }
}