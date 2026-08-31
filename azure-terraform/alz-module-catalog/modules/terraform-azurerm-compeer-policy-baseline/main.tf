# ============================================================================
# PATTERN MODULE: policy definitions/initiatives/assignments are composed here intentionally; scope ownership must remain explicit.
# ============================================================================

locals {
  policy_definition_ids = { for key, value in azurerm_policy_definition.this : key => value.id }
  policy_set_ids        = { for key, value in azurerm_policy_set_definition.this : key => value.id }

  management_group_exemptions = {
    for key, exemption in var.exemptions : key => exemption
    if exemption.scope_type == "management_group"
  }

  subscription_exemptions = {
    for key, exemption in var.exemptions : key => exemption
    if exemption.scope_type == "subscription"
  }

  resource_group_exemptions = {
    for key, exemption in var.exemptions : key => exemption
    if exemption.scope_type == "resource_group"
  }
}

resource "azurerm_policy_definition" "this" {
  for_each = var.policy_definitions

  name                = coalesce(try(each.value.name, null), each.key)
  policy_type         = try(each.value.policy_type, "Custom")
  mode                = try(each.value.mode, "All")
  display_name        = each.value.display_name
  description         = try(each.value.description, null)
  management_group_id = try(each.value.management_group_id, null)
  metadata            = try(each.value.metadata, null) == null ? null : jsonencode(each.value.metadata)
  parameters          = try(each.value.parameters, null) == null ? null : jsonencode(each.value.parameters)
  policy_rule         = jsonencode(each.value.policy_rule)
}

resource "azurerm_policy_set_definition" "this" {
  for_each = var.policy_set_definitions

  name                = coalesce(try(each.value.name, null), each.key)
  policy_type         = try(each.value.policy_type, "Custom")
  display_name        = each.value.display_name
  description         = try(each.value.description, null)
  management_group_id = try(each.value.management_group_id, null)
  metadata            = try(each.value.metadata, null) == null ? null : jsonencode(each.value.metadata)
  parameters          = try(each.value.parameters, null) == null ? null : jsonencode(each.value.parameters)

  dynamic "policy_definition_reference" {
    for_each = each.value.policy_definition_references
    content {
      policy_definition_id = coalesce(
        try(policy_definition_reference.value.policy_definition_id, null),
        try(local.policy_definition_ids[policy_definition_reference.value.policy_definition_key], null)
      )
      reference_id       = try(policy_definition_reference.value.reference_id, null)
      parameter_values   = try(policy_definition_reference.value.parameter_values, null) == null ? null : jsonencode(policy_definition_reference.value.parameter_values)
      policy_group_names = try(policy_definition_reference.value.policy_group_names, try(policy_definition_reference.value.group_names, null))
    }
  }
}

resource "azurerm_management_group_policy_assignment" "this" {
  for_each = var.management_group_assignments

  name                 = coalesce(try(each.value.name, null), each.key)
  management_group_id  = each.value.management_group_id
  policy_definition_id = coalesce(try(each.value.policy_definition_id, null), try(local.policy_definition_ids[each.value.policy_definition_key], null), try(local.policy_set_ids[each.value.policy_set_definition_key], null))
  display_name         = try(each.value.display_name, null)
  description          = try(each.value.description, null)
  enforce              = try(each.value.enforce, true)
  location             = try(each.value.location, null)
  parameters           = try(each.value.parameters, null) == null ? null : jsonencode(each.value.parameters)

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
      content                        = non_compliance_message.value
      policy_definition_reference_id = non_compliance_message.key == "default" ? null : non_compliance_message.key
    }
  }
}

resource "azurerm_subscription_policy_assignment" "this" {
  for_each = var.subscription_assignments

  name                 = coalesce(try(each.value.name, null), each.key)
  subscription_id      = each.value.subscription_id
  policy_definition_id = coalesce(try(each.value.policy_definition_id, null), try(local.policy_definition_ids[each.value.policy_definition_key], null), try(local.policy_set_ids[each.value.policy_set_definition_key], null))
  display_name         = try(each.value.display_name, null)
  description          = try(each.value.description, null)
  enforce              = try(each.value.enforce, true)
  location             = try(each.value.location, null)
  parameters           = try(each.value.parameters, null) == null ? null : jsonencode(each.value.parameters)

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
      content                        = non_compliance_message.value
      policy_definition_reference_id = non_compliance_message.key == "default" ? null : non_compliance_message.key
    }
  }
}

resource "azurerm_resource_group_policy_assignment" "this" {
  for_each = var.resource_group_assignments

  name                 = coalesce(try(each.value.name, null), each.key)
  resource_group_id    = each.value.resource_group_id
  policy_definition_id = coalesce(try(each.value.policy_definition_id, null), try(local.policy_definition_ids[each.value.policy_definition_key], null), try(local.policy_set_ids[each.value.policy_set_definition_key], null))
  display_name         = try(each.value.display_name, null)
  description          = try(each.value.description, null)
  enforce              = try(each.value.enforce, true)
  location             = try(each.value.location, null)
  parameters           = try(each.value.parameters, null) == null ? null : jsonencode(each.value.parameters)

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
      content                        = non_compliance_message.value
      policy_definition_reference_id = non_compliance_message.key == "default" ? null : non_compliance_message.key
    }
  }
}

resource "azurerm_management_group_policy_exemption" "this" {
  for_each = local.management_group_exemptions

  name                            = each.key
  management_group_id             = each.value.management_group_id
  policy_assignment_id            = each.value.policy_assignment_id
  exemption_category              = try(each.value.exemption_category, "Waiver")
  display_name                    = try(each.value.display_name, null)
  description                     = try(each.value.description, null)
  expires_on                      = try(each.value.expires_on, null)
  metadata                        = try(each.value.metadata, null) == null ? null : jsonencode(each.value.metadata)
  policy_definition_reference_ids = try(each.value.policy_definition_ids, null)
}

resource "azurerm_subscription_policy_exemption" "this" {
  for_each = local.subscription_exemptions

  name                            = each.key
  subscription_id                 = each.value.subscription_id
  policy_assignment_id            = each.value.policy_assignment_id
  exemption_category              = try(each.value.exemption_category, "Waiver")
  display_name                    = try(each.value.display_name, null)
  description                     = try(each.value.description, null)
  expires_on                      = try(each.value.expires_on, null)
  metadata                        = try(each.value.metadata, null) == null ? null : jsonencode(each.value.metadata)
  policy_definition_reference_ids = try(each.value.policy_definition_ids, null)
}

resource "azurerm_resource_group_policy_exemption" "this" {
  for_each = local.resource_group_exemptions

  name                            = each.key
  resource_group_id               = each.value.resource_group_id
  policy_assignment_id            = each.value.policy_assignment_id
  exemption_category              = try(each.value.exemption_category, "Waiver")
  display_name                    = try(each.value.display_name, null)
  description                     = try(each.value.description, null)
  expires_on                      = try(each.value.expires_on, null)
  metadata                        = try(each.value.metadata, null) == null ? null : jsonencode(each.value.metadata)
  policy_definition_reference_ids = try(each.value.policy_definition_ids, null)
}
