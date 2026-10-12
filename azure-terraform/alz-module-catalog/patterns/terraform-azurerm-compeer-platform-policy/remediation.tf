# Validate the contract before creating DINE/Modify assignments.
resource "terraform_data" "remediation_contract" {
  count = length(local.rem_assignments) > 0 ? 1 : 0

  input = sort(keys(local.rem_assignments))

  lifecycle {
    precondition {
      condition = alltrue([for assignment in values(local.rem_assignments) :
        contains(keys(local.management_group_scope_ids), coalesce(try(assignment.management_group_key, null), local.rem_mg_key, "unset"))
      ])
      error_message = "Each remediation assignment must resolve an existing management_group_key, individually or from remediation.management_group_key."
    }
    precondition {
      condition = alltrue([
        for k, v in local.rem_assignments : !try(v.inject_law, false) || local.rem_law_id != null
      ])
      error_message = "A remediation assignment sets inject_law but remediation.log_analytics_workspace_id is not provided."
    }
  }
}

resource "azurerm_role_assignment" "remediation" {
  for_each = local.remediation_role_assignments

  scope                            = local.management_group_scope_ids[each.value.management_group_key]
  role_definition_id               = each.value.role_definition_id
  principal_id                     = module.policy.management_group_assignment_principal_ids[each.value.assignment_key]
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true

  depends_on = [terraform_data.remediation_contract]
}

# Existing resources are remediated only by an explicitly approved task.
resource "azurerm_management_group_policy_remediation" "task" {
  for_each = local.rem_enabled ? var.remediation.tasks : {}

  name                           = each.key
  management_group_id            = try(local.remediation_assignments_input["rem-${each.value.assignment_key}"].management_group_id, null)
  policy_assignment_id           = try(module.policy.management_group_assignment_ids["rem-${each.value.assignment_key}"], null)
  policy_definition_reference_id = each.value.policy_definition_reference_id
  location_filters               = each.value.location_filters
  resource_count                 = each.value.resource_count
  parallel_deployments           = each.value.parallel_deployments
  failure_percentage             = each.value.failure_percentage

  lifecycle {
    precondition {
      condition     = contains(keys(local.rem_assignments), each.value.assignment_key)
      error_message = "Remediation task assignment_key must identify an enabled DINE assignment."
    }
    precondition {
      condition = try(
        contains(["DeployIfNotExists", "Modify"], coalesce(try(local.rem_assignments[each.value.assignment_key].parameters.effect.value, null), "DeployIfNotExists")) &&
        length(local.rem_assignments[each.value.assignment_key].role_definition_ids) > 0 &&
        ((try(local.rem_assignments[each.value.assignment_key].policy_set_definition_id, null) == null && try(local.rem_assignments[each.value.assignment_key].policy_set_definition_key, null) == null) ||
        length(trimspace(coalesce(each.value.policy_definition_reference_id, " "))) > 0), false
      )
      error_message = "Tasks require an active assignment with remediation RBAC; initiative tasks also require a policy_definition_reference_id."
    }
  }

  depends_on = [azurerm_role_assignment.remediation]
}
