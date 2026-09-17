# =============================================================================
# Resource-group-scope assignments + policy exemptions (all three scopes).
#
# The platform-policy pattern is the single home for policy exemptions and
# remediation. The resource mechanics for all of this - definitions,
# initiatives, MG/subscription/resource-group assignments, exemptions - live
# in modules/terraform-azurerm-compeer-policy; this pattern only decides
# which entries exist and where they apply. See main.tf's resolved-input
# locals for the management_group_key -> management_group_id resolution
# these entries still need before reaching module.policy.
# =============================================================================

locals {
  resource_group_policy_assignments_input = var.resource_group_policy_assignments

  # policy_assignment_key resolves against module.policy's OWN merged
  # assignment map (all 3 scopes, including remediation's "rem-<key>"
  # entries) - that resolution stays inside the module, since the referenced
  # ID is a value the module itself computes. management_group_key here is
  # the one thing that DOES need resolving here, since the MG catalog is
  # external to the module.
  policy_exemptions_input = {
    for k, v in var.policy_exemptions : k => merge(
      { for ik, iv in v : ik => iv if ik != "management_group_key" && ik != "management_group_id" },
      { management_group_id = coalesce(try(v.management_group_id, null), try(local.management_group_scope_ids[v.management_group_key], null)) }
    )
  }
}
