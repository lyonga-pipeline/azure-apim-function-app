resource "terraform_data" "contract" {
  for_each = var.contracts

  input = {
    phase                = each.value.phase
    owner                = try(each.value.owner, null)
    enabled              = each.value.enabled
    cost_disabled        = each.value.cost_disabled
    implementation_state = each.value.implementation_state
    required_controls    = each.value.required_controls
    evidence_locations   = each.value.evidence_locations
    notes                = try(each.value.notes, null)
  }

  lifecycle {
    precondition {
      condition     = !(each.value.enabled && each.value.implementation_state == "contract-only")
      error_message = "Enabled operational contracts must reference an implemented module, external system, or approved runbook."
    }
  }
}
