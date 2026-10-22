resource "terraform_data" "deployment_contract" {
  count = local.enabled ? 1 : 0
  lifecycle {
    precondition {
      condition = alltrue([for id in [var.subscription_id, var.tenant_id] :
        can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", id)) && id != "00000000-0000-0000-0000-000000000000"
      ])
      error_message = "Set real workload subscription_id and tenant_id in HCP before enabling deployment."
    }
    precondition {
      condition     = !var.use_tfe_outputs || (var.tfe_organization != null && length(local.management) > 0 && length(local.connectivity) > 0 && length(local.governance) > 0)
      error_message = "Public platform outputs are unreadable. Confirm exact HCP workspace names and scoped output-read access, or explicitly use approved platform_inputs with use_tfe_outputs=false."
    }
    precondition {
      condition     = length(local.platform.mandatory_tag_keys) > 0
      error_message = "The governance contract must publish non-empty mandatory_tag_keys, or provide their explicitly approved equivalent in platform_inputs."
    }
  }
}
