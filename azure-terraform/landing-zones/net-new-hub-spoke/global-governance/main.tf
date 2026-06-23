locals {
  root_management_groups = {
    for key, value in var.management_groups : key => value
    if try(value.parent_key, "root") == "root"
  }

  child_management_groups = {
    for key, value in var.management_groups : key => value
    if try(value.parent_key, "root") != "root"
  }
}

resource "azurerm_management_group" "root" {
  for_each = local.root_management_groups

  name                       = each.key
  display_name               = each.value.display_name
  parent_management_group_id = var.root_management_group_id
}

resource "azurerm_management_group" "child" {
  for_each = local.child_management_groups

  name                       = each.key
  display_name               = each.value.display_name
  parent_management_group_id = azurerm_management_group.root[each.value.parent_key].id
}

resource "azurerm_management_group_subscription_association" "this" {
  for_each = var.subscription_placements

  management_group_id = local.management_group_scope_ids[each.value.management_group_key]
  subscription_id     = each.value.subscription_id
}

locals {
  management_group_scope_ids = merge(
    {
      root = var.root_management_group_id
    },
    {
      for key, value in azurerm_management_group.root : key => value.id
    },
    {
      for key, value in azurerm_management_group.child : key => value.id
    }
  )

  policy_definition_ids = {
    for key, value in azurerm_policy_definition.this : key => value.id
  }

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
  for_each = var.custom_policy_definitions

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

module "custom_role_definitions" {
  source   = "../../../modules/role-definition"
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
  source = "../../../modules/role-assignments"

  assignments = local.role_assignment_inputs
}

resource "azurerm_management_group_policy_assignment" "this" {
  for_each = var.management_group_policy_assignments

  name                 = try(each.value.name, each.key)
  management_group_id  = local.management_group_scope_ids[each.value.management_group_key]
  policy_definition_id = coalesce(try(each.value.policy_definition_id, null), try(local.policy_definition_ids[each.value.policy_definition_key], null))
  display_name         = try(each.value.display_name, null)
  description          = try(each.value.description, null)
  enforce              = try(each.value.enforce, true)
  location             = try(each.value.identity, null) == null ? null : try(each.value.location, var.policy_assignment_location)
  metadata             = jsonencode(try(each.value.metadata, {}))
  parameters           = jsonencode(try(each.value.parameters, {}))
  not_scopes           = try(each.value.not_scopes, null)

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

  name                 = try(each.value.name, each.key)
  subscription_id      = each.value.subscription_id
  policy_definition_id = coalesce(try(each.value.policy_definition_id, null), try(local.policy_definition_ids[each.value.policy_definition_key], null))
  display_name         = try(each.value.display_name, null)
  description          = try(each.value.description, null)
  enforce              = try(each.value.enforce, true)
  location             = try(each.value.identity, null) == null ? null : try(each.value.location, var.policy_assignment_location)
  metadata             = jsonencode(try(each.value.metadata, {}))
  parameters           = jsonencode(try(each.value.parameters, {}))
  not_scopes           = try(each.value.not_scopes, null)

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
