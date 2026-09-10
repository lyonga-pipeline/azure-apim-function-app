locals {
  root_parent_management_group_value = trimspace(var.root_management_group_id == null ? "" : var.root_management_group_id)
  root_parent_management_group_id = (
    local.root_parent_management_group_value == "" ? null :
    startswith(local.root_parent_management_group_value, "/providers/Microsoft.Management/managementGroups/") ? local.root_parent_management_group_value :
    "/providers/Microsoft.Management/managementGroups/${local.root_parent_management_group_value}"
  )

  # Fan the flat subscription_placements map out into the per-group
  # subscription_ids sets the management-groups module consumes.
  subscription_ids_by_management_group = {
    for mg_key in keys(var.management_groups) : mg_key => [
      for _, placement in var.subscription_placements : placement.subscription_id
      if placement.management_group_key == mg_key
    ]
  }
}

moved {
  from = azurerm_management_group.root
  to   = module.management_groups.azurerm_management_group.root
}

moved {
  from = azurerm_management_group.level_1
  to   = module.management_groups.azurerm_management_group.level_1
}

moved {
  from = azurerm_management_group.level_2
  to   = module.management_groups.azurerm_management_group.level_2
}

moved {
  from = azurerm_management_group.level_3
  to   = module.management_groups.azurerm_management_group.level_3
}

module "management_groups" {
  source = "../../modules/terraform-azurerm-compeer-management-groups"

  root_parent_management_group_id = local.root_parent_management_group_id

  management_groups = {
    for key, value in var.management_groups : key => {
      display_name     = value.display_name
      parent_key       = try(value.parent_key, "root") == "root" ? null : value.parent_key
      subscription_ids = local.subscription_ids_by_management_group[key]
    }
  }
}

locals {
  # `root` keeps the tenant-root (or configured parent) scope reachable for
  # policy, RBAC, and budget blocks that target `management_group_key = "root"`.
  management_group_scope_ids = merge(
    { root = local.root_parent_management_group_id },
    module.management_groups.management_group_ids
  )

  policy_definition_ids = {
    for key, value in azurerm_policy_definition.this : key => value.id
  }

  policy_set_definition_ids = {
    for key, value in azurerm_policy_set_definition.this : key => value.id
  }

  policy_assignment_definition_ids = merge(
    local.policy_definition_ids,
    local.policy_set_definition_ids
  )

  role_assignment_inputs = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      scope = coalesce(
        try(assignment.scope, null),
        try(local.management_group_scope_ids[assignment.management_group_key], null)
      )
    })
  }
}

resource "azurerm_policy_definition" "this" {
  for_each = merge(var.custom_policy_definitions, local.pb_definitions)

  name                = each.key
  display_name        = each.value.display_name
  policy_type         = try(each.value.policy_type, "Custom")
  mode                = try(each.value.mode, "Indexed")
  management_group_id = local.management_group_scope_ids[each.value.management_group_key]
  description         = try(each.value.description, null)
  metadata            = jsonencode(try(each.value.metadata, {}))
  parameters          = jsonencode(try(each.value.parameters, {}))
  policy_rule         = jsonencode(each.value.policy_rule)
}

resource "azurerm_policy_set_definition" "this" {
  for_each = var.custom_policy_set_definitions

  name                = each.key
  display_name        = each.value.display_name
  policy_type         = try(each.value.policy_type, "Custom")
  management_group_id = local.management_group_scope_ids[each.value.management_group_key]
  description         = try(each.value.description, null)
  metadata            = jsonencode(try(each.value.metadata, {}))
  parameters          = jsonencode(try(each.value.parameters, {}))

  dynamic "policy_definition_reference" {
    for_each = each.value.policy_definition_references
    content {
      policy_definition_id = coalesce(
        try(policy_definition_reference.value.policy_definition_id, null),
        try(local.policy_definition_ids[policy_definition_reference.value.policy_definition_key], null)
      )
      parameter_values   = jsonencode(try(policy_definition_reference.value.parameter_values, {}))
      reference_id       = try(policy_definition_reference.value.reference_id, policy_definition_reference.key)
      policy_group_names = try(policy_definition_reference.value.policy_group_names, null)
    }
  }
}

module "custom_role_definitions" {
  source   = "../../modules/terraform-azurerm-compeer-role-definition"
  for_each = var.custom_role_definitions

  name               = each.value.name
  scope              = coalesce(try(each.value.scope, null), local.management_group_scope_ids[each.value.management_group_key])
  description        = try(each.value.description, null)
  role_definition_id = try(each.value.role_definition_id, null)
  assignable_scopes = coalesce(
    try(each.value.assignable_scopes, null),
    [coalesce(try(each.value.scope, null), local.management_group_scope_ids[each.value.management_group_key])]
  )
  permissions = each.value.permissions
}

module "role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.role_assignment_inputs
}

resource "azurerm_management_group_policy_assignment" "this" {
  for_each = merge(var.management_group_policy_assignments, local.pb_assignments)

  name                = try(each.value.name, each.key)
  management_group_id = local.management_group_scope_ids[each.value.management_group_key]
  policy_definition_id = coalesce(
    try(each.value.policy_definition_id, null),
    try(each.value.policy_set_definition_id, null),
    try(local.policy_definition_ids[each.value.policy_definition_key], null),
    try(local.policy_set_definition_ids[each.value.policy_set_definition_key], null)
  )
  display_name = try(each.value.display_name, null)
  description  = try(each.value.description, null)
  enforce      = try(each.value.enforce, true)
  location     = try(each.value.identity, null) == null ? null : try(each.value.location, var.policy_assignment_location)
  metadata     = jsonencode(try(each.value.metadata, {}))
  parameters   = jsonencode(try(each.value.parameters, {}))
  not_scopes   = try(each.value.not_scopes, null)

  dynamic "identity" {
    for_each = try(each.value.identity, null) == null ? [] : [each.value.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "non_compliance_message" {
    for_each = try(each.value.non_compliance_messages, {})
    content {
      content                        = non_compliance_message.value.content
      policy_definition_reference_id = try(non_compliance_message.value.policy_definition_reference_id, null)
    }
  }
}

resource "azurerm_subscription_policy_assignment" "this" {
  for_each = var.subscription_policy_assignments

  name            = try(each.value.name, each.key)
  subscription_id = each.value.subscription_id
  policy_definition_id = coalesce(
    try(each.value.policy_definition_id, null),
    try(each.value.policy_set_definition_id, null),
    try(local.policy_definition_ids[each.value.policy_definition_key], null),
    try(local.policy_set_definition_ids[each.value.policy_set_definition_key], null)
  )
  display_name = try(each.value.display_name, null)
  description  = try(each.value.description, null)
  enforce      = try(each.value.enforce, true)
  location     = try(each.value.identity, null) == null ? null : try(each.value.location, var.policy_assignment_location)
  metadata     = jsonencode(try(each.value.metadata, {}))
  parameters   = jsonencode(try(each.value.parameters, {}))
  not_scopes   = try(each.value.not_scopes, null)

  dynamic "identity" {
    for_each = try(each.value.identity, null) == null ? [] : [each.value.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  dynamic "non_compliance_message" {
    for_each = try(each.value.non_compliance_messages, {})
    content {
      content                        = non_compliance_message.value.content
      policy_definition_reference_id = try(non_compliance_message.value.policy_definition_reference_id, null)
    }
  }
}

resource "azurerm_consumption_budget_management_group" "this" {
  for_each = var.management_group_budgets

  name                = each.key
  management_group_id = local.management_group_scope_ids[each.value.management_group_key]
  amount              = each.value.amount
  time_grain          = each.value.time_grain

  time_period {
    start_date = each.value.time_period.start_date
    end_date   = try(each.value.time_period.end_date, null)
  }

  dynamic "notification" {
    for_each = each.value.notifications
    content {
      enabled        = try(notification.value.enabled, true)
      threshold      = notification.value.threshold
      operator       = notification.value.operator
      threshold_type = try(notification.value.threshold_type, "Actual")
      contact_emails = try(notification.value.contact_emails, null)
    }
  }
}
