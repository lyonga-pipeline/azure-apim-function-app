terraform {
  required_version = ">= 1.5, < 2.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.11, < 5.0"
    }
  }
}
