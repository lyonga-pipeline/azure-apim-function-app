terraform {
  required_version = ">= 1.5, < 2.0"
}

module "tags" {
  source = "../.."

  environment         = "prod"
  application         = "landing-zone"
  owner               = "cloud-platform"
  source_repo         = "ado://project/repo"
  created_on          = "2026-09-09"
  criticality_tier    = "tier1"
  data_classification = "confidential"
  lifecycle_state     = "active"
  cost_center         = "CC-1000"
  gl_category         = "opex-cloud"

  additional_tags = {
    business_unit = "technology"
  }
}

output "tags" {
  value = module.tags.tags
}
