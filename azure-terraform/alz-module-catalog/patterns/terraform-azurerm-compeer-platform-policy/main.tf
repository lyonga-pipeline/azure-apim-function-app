# Policy definitions have no Appendix F naming-module row at all (only
# initiatives and assignments do) - real names here are explicit,
# hand-chosen ("cmp-<topic>") by design, not a naming-module default. Policy
# initiative names need BOTH a domain and a purpose token
# (initiative-<domain>-<purpose>), which a single flat map key can't safely
# supply without guessing a split - so these are opt-in: set `domain` on an
# entry to compute a name via the naming module, otherwise the explicit
# `name` (today's convention for all real entries) is required as before.
module "naming_initiative" {
  source      = "../../modules/terraform-azurerm-compeer-naming"
  for_each    = merge(var.custom_policy_set_definitions, local.poc_set_definitions)
  region      = "centralus"
  environment = "shared"
  domain      = try(each.value.domain, null)
  purpose     = each.key
}

module "naming_assignment" {
  source       = "../../modules/terraform-azurerm-compeer-naming"
  for_each     = merge(var.management_group_policy_assignments, local.poc_assignments, var.subscription_policy_assignments)
  region       = "centralus"
  environment  = "shared"
  policy       = try(each.value.policy, null)
  policy_scope = try(each.value.policy_scope, null)
}

locals {
  management_group_scope_ids = {
    for key, value in var.management_group_ids : key => (
      startswith(value, "/providers/Microsoft.Management/managementGroups/") ? value : "/providers/Microsoft.Management/managementGroups/${value}"
    )
  }

  # -----------------------------------------------------------------------
  # Resolve management_group_key -> a concrete management_group_id and drop
  # the key before handing entries to module.policy - that module has no
  # concept of this pattern's MG catalog (see
  # modules/terraform-azurerm-compeer-policy's README "Boundary" section).
  # policy_definition_key / policy_set_definition_key / policy_assignment_key
  # are left untouched: those resolve against sibling definitions/initiatives
  # /assignments the module itself creates in the same call, so the module
  # keeps doing that resolution internally. module.policy's variables are
  # typed `any` (not a strict object schema) specifically so this
  # filter-then-merge works: real policy parameters/policy_rule/metadata have
  # a genuinely different attribute key set per policy, and only `any` avoids
  # a "cannot find a common base type" module-boundary error across such a
  # map.
  #
  # remediation.tf's DINE assignments (local.rem_assignments) fold into the
  # same management_group_assignments map here, keyed "rem-<key>" - they're
  # just management-group policy assignments with a SystemAssigned identity
  # and LAW-parameter-injection business logic that remediation.tf still
  # owns; the resource mechanics live in module.policy like everything else.
  # -----------------------------------------------------------------------

  policy_definitions_input = {
    for k, v in merge(var.custom_policy_definitions, local.poc_definitions) : k => merge(
      { for ik, iv in v : ik => iv if ik != "management_group_key" && ik != "management_group_id" },
      { management_group_id = coalesce(try(v.management_group_id, null), try(local.management_group_scope_ids[v.management_group_key], null)) }
    )
  }

  policy_set_definitions_input = {
    for k, v in merge(var.custom_policy_set_definitions, local.poc_set_definitions) : k => merge(
      { for ik, iv in v : ik => iv if ik != "management_group_key" && ik != "management_group_id" && ik != "domain" },
      {
        name                = coalesce(try(v.name, null), module.naming_initiative[k].policy_initiative, k)
        management_group_id = coalesce(try(v.management_group_id, null), try(local.management_group_scope_ids[v.management_group_key], null))
      }
    )
  }

  management_group_policy_assignments_input = merge(
    {
      for k, v in merge(var.management_group_policy_assignments, local.poc_assignments) : k => merge(
        { for ik, iv in v : ik => iv if ik != "management_group_key" && ik != "management_group_id" && ik != "location" && ik != "policy" && ik != "policy_scope" },
        {
          name                = coalesce(try(v.name, null), module.naming_assignment[k].policy_assignment, k)
          management_group_id = coalesce(try(v.management_group_id, null), try(local.management_group_scope_ids[v.management_group_key], null))
          location            = try(v.identity, null) == null ? null : try(v.location, var.policy_assignment_location)
        }
      )
    },
    local.remediation_assignments_input
  )

  subscription_policy_assignments_input = {
    for k, v in var.subscription_policy_assignments : k => merge(
      { for ik, iv in v : ik => iv if ik != "location" && ik != "policy" && ik != "policy_scope" },
      {
        name     = coalesce(try(v.name, null), module.naming_assignment[k].policy_assignment, k)
        location = try(v.identity, null) == null ? null : try(v.location, var.policy_assignment_location)
      }
    )
  }
}

module "policy" {
  source = "../../modules/terraform-azurerm-compeer-policy"

  policy_definitions           = local.policy_definitions_input
  policy_set_definitions       = local.policy_set_definitions_input
  management_group_assignments = local.management_group_policy_assignments_input
  subscription_assignments     = local.subscription_policy_assignments_input
  resource_group_assignments   = local.resource_group_policy_assignments_input
  exemptions                   = local.policy_exemptions_input

  depends_on = [terraform_data.remediation_contract]
}
