data "tfe_outputs" "management" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.management_workspace_name
}

data "tfe_outputs" "authorization" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.authorization_workspace_name
}

locals {
  enabled = try(var.privileged_access.enabled, false)

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  authorization_outputs = merge(
    try(data.tfe_outputs.authorization[0].nonsensitive_values, {}),
    try(data.tfe_outputs.authorization[0].values, {})
  )

  group_object_ids = try(local.authorization_outputs.group_object_ids, {})

  log_analytics_workspace_id = coalesce(
    var.log_analytics_workspace_id,
    try(local.management_outputs.log_analytics_workspace_id, null),
    "unset",
  )

  unresolved_principal_placeholder = "00000000-0000-0000-0000-000000000000"

  # Resolve principal_group_key -> the authorization workspace's group object ID,
  # and strip the key so the object matches the pattern's typed contract.
  pim_eligible_role_assignments = {
    for key, assignment in try(var.privileged_access.pim_eligible_role_assignments, {}) : key => {
      scope              = assignment.scope
      role_definition_id = assignment.role_definition_id
      principal_id = try(assignment.principal_id, null) != null ? assignment.principal_id : try(
        local.group_object_ids[assignment.principal_group_key],
        local.unresolved_principal_placeholder,
      )
      justification     = try(assignment.justification, null)
      condition         = try(assignment.condition, null)
      condition_version = try(assignment.condition_version, null)
      schedule          = try(assignment.schedule, null)
      ticket            = try(assignment.ticket, null)
    }
  }

  # Same resolution for activation-policy approvers: an approver entry may set
  # object_id directly, or approver_group_key to resolve against
  # platform-authorization's group_object_ids (e.g. AZ-SEC-Admins approving
  # AZ-PLT-Admins activations).
  role_management_policies = {
    for key, policy in try(var.privileged_access.role_management_policies, {}) : key => {
      role_definition_id = policy.role_definition_id
      scope              = policy.scope
      activation_rules = try(policy.activation_rules, null) == null ? null : merge(
        policy.activation_rules,
        {
          approvers = [
            for approver in try(policy.activation_rules.approvers, []) : {
              type = try(approver.type, "Group")
              object_id = try(approver.object_id, null) != null ? approver.object_id : try(
                local.group_object_ids[approver.approver_group_key],
                local.unresolved_principal_placeholder,
              )
            }
          ]
        }
      )
      active_assignment_rules   = try(policy.active_assignment_rules, null)
      eligible_assignment_rules = try(policy.eligible_assignment_rules, null)
      notification_rules        = try(policy.notification_rules, {})
    }
  }
}

module "privileged_access" {
  source = "../../../../patterns/terraform-azurerm-compeer-privileged-access"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  pim_eligible_role_assignments    = local.pim_eligible_role_assignments
  role_management_policies         = local.role_management_policies
  break_glass_user_principal_names = try(var.privileged_access.break_glass_user_principal_names, [])
  log_analytics_workspace_id       = local.log_analytics_workspace_id == "unset" ? null : local.log_analytics_workspace_id
  break_glass_alert                = try(var.privileged_access.break_glass_alert, {})
  operational_contracts            = try(var.privileged_access.operational_contracts, {})
  tags                             = try(var.privileged_access.tags, {})
}
