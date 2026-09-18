terraform {
  required_version = ">= 1.5, < 2.0"
}

module "tags" {
  source = "../.."

  environment = "prod"
  application = "landing-zone"
  appcode     = "lz"
  owner       = "cloud-platform"
  source_repo = "ado://project/repo"
  # created_on is a real, frozen "first deployed" date, not today's date -
  # see the variable's own description for why this is never computed with
  # timestamp(). Passed in once by the deploying pipeline; hardcoded here
  # only because this is a static example.
  created_on          = "2026-09-09"
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
