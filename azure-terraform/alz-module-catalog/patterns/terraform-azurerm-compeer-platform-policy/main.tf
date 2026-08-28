locals {
  management_group_scope_ids = {
    for key, value in var.management_group_ids : key => (
      startswith(value, "/providers/Microsoft.Management/managementGroups/") ? value : "/providers/Microsoft.Management/managementGroups/${value}"
    )
  }

  policy_definition_ids = {
    for key, value in azurerm_policy_definition.this : key => value.id
  }

  policy_set_definition_ids = {
    for key, value in azurerm_policy_set_definition.this : key => value.id
  }
}

resource "azurerm_policy_definition" "this" {
  for_each = var.custom_policy_definitions

  name                = each.key
  display_name        = each.value.display_name
  policy_type         = try(each.value.policy_type, "Custom")
  mode                = try(each.value.mode, "Indexed")
  management_group_id = coalesce(try(each.value.management_group_id, null), try(local.management_group_scope_ids[each.value.management_group_key], null))
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
  management_group_id = coalesce(try(each.value.management_group_id, null), try(local.management_group_scope_ids[each.value.management_group_key], null))
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

resource "azurerm_management_group_policy_assignment" "this" {
  for_each = var.management_group_policy_assignments

  name                = try(each.value.name, each.key)
  management_group_id = coalesce(try(each.value.management_group_id, null), try(local.management_group_scope_ids[each.value.management_group_key], null))
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
