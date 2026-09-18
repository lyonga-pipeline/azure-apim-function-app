terraform {
  required_version = ">= 1.5, < 2.0"

  required_providers {
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13"
    }
  }
}

# For a single root deploying one thing, one time_static resource (see the
# ../basic example) is enough. For a root that deploys a GROWING map of
# similar resources over time - here, storage accounts added to this root
# on different dates - a single shared time_static would give every account
# the same created_on, including ones added months later. Keying time_static
# by the same stable key as the resource map instead gives each entry its
# own frozen first-deployed date: adding a new key later creates only that
# key's time_static (and therefore only that key's created_on) - every
# already-existing key's value is read back from state, unchanged.
variable "storage_account_keys" {
  type        = set(string)
  description = "Logical keys of the storage accounts this root deploys - same keys used for their tags below."
}

resource "time_static" "storage_created" {
  for_each = var.storage_account_keys
}

module "tags" {
  source   = "../.."
  for_each = var.storage_account_keys

  environment = "prod"
  application = "landing-zone"
  appcode     = "lz"
  owner       = "cloud-platform"
  source_repo = "ado://project/repo"
  created_on  = formatdate("YYYY-MM-DD", time_static.storage_created[each.key].rfc3339)

  criticality_tier    = "tier-0"
  data_classification = "confidential"
  lifecycle_state     = "active"
  cost_center         = "CC-1000"
  gl_category         = "opex-cloud"
}

output "tags_by_key" {
  value = { for key, mod in module.tags : key => mod.tags }
}
