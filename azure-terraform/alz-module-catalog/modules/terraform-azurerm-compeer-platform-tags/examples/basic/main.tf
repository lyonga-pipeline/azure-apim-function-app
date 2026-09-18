terraform {
  required_version = ">= 1.5, < 2.0"

  required_providers {
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

# created_on must be a real, frozen "first deployed" date, not today's date -
# see the variable's own description for why this is never computed with
# timestamp(). time_static computes its value once, on this resource's first
# apply, and stores it in state; every later plan reuses that same value
# instead of recomputing it. This resource intentionally lives in the
# CONSUMING ROOT, not in the tags module itself - the root owns the
# deployment-lifecycle boundary.
resource "time_static" "deployment_created" {}

module "tags" {
  source = "../.."

  environment = "prod"
  application = "landing-zone"
  appcode     = "lz"
  owner       = "cloud-platform"
  source_repo = "ado://project/repo"
  created_on  = formatdate("YYYY-MM-DD", time_static.deployment_created.rfc3339)

  criticality_tier    = "tier-0"
  data_classification = "confidential"
  lifecycle_state     = "active"
  cost_center         = "CC-1000"
  gl_category         = "opex-cloud"
  # created_by defaults to "Terraform" - not set here on purpose, to
  # demonstrate that default.

  additional_tags = {
    business_unit = "technology"
  }
}

output "tags" {
  value = module.tags.tags
}
