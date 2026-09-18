# =============================================================================
# GENERIC AZURE POLICY MODULE
#
# "I know how to create Azure Policy objects correctly." Definitions,
# initiatives, MG/subscription/resource-group assignments, and exemptions -
# nothing ALZ-specific lives here. Which policies exist, what they say, and
# where they get assigned is the calling PATTERN's decision (global-governance
# decides the baseline; platform-policy decides the private-only/remediation
# guardrails); this module only knows how to turn an already-decided map into
# the matching azurerm resources.
#
# Every management_group_id / subscription_id / resource_group_id input is a
# CONCRETE, already-resolved resource ID - see the note in variables.tf.
# =============================================================================

locals {
  policy_definition_ids = { for key, value in azurerm_policy_definition.definition : key => value.id }
  policy_set_ids        = { for key, value in azurerm_management_group_policy_set_definition.initiative : key => value.id }

  # Assignments this SAME module call creates, across all 3 scopes - lets an
  # exemption reference one by policy_assignment_key instead of a raw ID.
  assignment_ids = merge(
    { for key, value in azurerm_management_group_policy_assignment.mg_assignment : key => value.id },
    { for key, value in azurerm_subscription_policy_assignment.subscription_assignment : key => value.id },
    { for key, value in azurerm_resource_group_policy_assignment.rg_assignment : key => value.id },
  )

  management_group_exemptions = { for key, exemption in var.exemptions : key => exemption if exemption.scope_type == "management_group" }
  subscription_exemptions     = { for key, exemption in var.exemptions : key => exemption if exemption.scope_type == "subscription" }
  resource_group_exemptions   = { for key, exemption in var.exemptions : key => exemption if exemption.scope_type == "resource_group" }
}

# azurerm_policy_definition.management_group_id is NOT deprecated in the
# azurerm provider version this module pins (>= 4.42, < 5.0 - confirmed
# empirically against the installed 4.81.0 schema: the attribute carries no
# `deprecated` flag here). A generic Checkmarx/linter rule can still flag it
# because it flags the argument name across every resource that has it,
# regardless of per-resource deprecation status. There is also no dedicated
# azurerm_management_group_policy_definition resource in this provider
# version to migrate to. Left as-is; azurerm_policy_set_definition below is
# the one that actually needed migrating.
resource "azurerm_policy_definition" "definition" {
  for_each = var.policy_definitions

  name                = coalesce(try(each.value.name, null), each.key)
  policy_type         = try(each.value.policy_type, "Custom")
  mode                = try(each.value.mode, "Indexed")
  display_name        = each.value.display_name
  description         = try(each.value.description, null)
  management_group_id = each.value.management_group_id
  metadata            = jsonencode(try(each.value.metadata, {}))
  parameters          = jsonencode(try(each.value.parameters, {}))
  policy_rule         = jsonencode(each.value.policy_rule)
}

# azurerm_policy_set_definition.management_group_id IS deprecated in this
# provider version (confirmed empirically against the installed 4.81.0
# schema: the attribute carries `deprecated: true`), in favor of this
# dedicated resource - which also makes management_group_id required rather
# than optional, matching this module's own contract that every
# policy_set_definitions entry already supplies a concrete
# management_group_id (see variables.tf), so no for_each split is needed.
resource "azurerm_management_group_policy_set_definition" "initiative" {
  for_each = var.policy_set_definitions

  name = coalesce(try(each.value.name, null), each.key)
  # policy_type is optional on the generic azurerm_policy_set_definition
  # (defaults to "Custom" there) but required on this dedicated resource -
  # try() already supplies a concrete value either way, so no behavior
  # change for existing callers that never set it.
  policy_type         = try(each.value.policy_type, "Custom")
  display_name        = each.value.display_name
  description         = try(each.value.description, null)
  management_group_id = each.value.management_group_id
  metadata            = jsonencode(try(each.value.metadata, {}))
  parameters          = jsonencode(try(each.value.parameters, {}))

  dynamic "policy_definition_reference" {
    for_each = each.value.policy_definition_references
    content {
      policy_definition_id = coalesce(
        try(policy_definition_reference.value.policy_definition_id, null),
        try(local.policy_definition_ids[policy_definition_reference.value.policy_definition_key], null)
      )
      reference_id       = try(policy_definition_reference.value.reference_id, null)
      parameter_values   = try(policy_definition_reference.value.parameter_values, null) == null ? null : jsonencode(policy_definition_reference.value.parameter_values)
      policy_group_names = try(policy_definition_reference.value.policy_group_names, null)
    }
  }
}

resource "azurerm_management_group_policy_assignment" "mg_assignment" {
  for_each = var.management_group_assignments

  name                = coalesce(try(each.value.name, null), each.key)
  management_group_id = each.value.management_group_id
  policy_definition_id = coalesce(
    try(each.value.policy_definition_id, null),
    try(each.value.policy_set_definition_id, null),
    try(local.policy_definition_ids[each.value.policy_definition_key], null),
    try(local.policy_set_ids[each.value.policy_set_definition_key], null),
  )
  display_name = try(each.value.display_name, null)
  description  = try(each.value.description, null)
  enforce      = try(each.value.enforce, true)
  location     = try(each.value.location, null)
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

resource "azurerm_subscription_policy_assignment" "subscription_assignment" {
  for_each = var.subscription_assignments

  name            = coalesce(try(each.value.name, null), each.key)
  subscription_id = each.value.subscription_id
  policy_definition_id = coalesce(
    try(each.value.policy_definition_id, null),
    try(each.value.policy_set_definition_id, null),
    try(local.policy_definition_ids[each.value.policy_definition_key], null),
    try(local.policy_set_ids[each.value.policy_set_definition_key], null),
  )
  display_name = try(each.value.display_name, null)
  description  = try(each.value.description, null)
  enforce      = try(each.value.enforce, true)
  location     = try(each.value.location, null)
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

resource "azurerm_resource_group_policy_assignment" "rg_assignment" {
  for_each = var.resource_group_assignments

  name              = coalesce(try(each.value.name, null), each.key)
  resource_group_id = each.value.resource_group_id
  policy_definition_id = coalesce(
    try(each.value.policy_definition_id, null),
    try(each.value.policy_set_definition_id, null),
    try(local.policy_definition_ids[each.value.policy_definition_key], null),
    try(local.policy_set_ids[each.value.policy_set_definition_key], null),
  )
  display_name = try(each.value.display_name, null)
  description  = try(each.value.description, null)
  enforce      = try(each.value.enforce, true)
  location     = try(each.value.location, null)
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

resource "azurerm_management_group_policy_exemption" "mg_exemption" {
  for_each = local.management_group_exemptions

  name                            = each.key
  management_group_id             = each.value.management_group_id
  policy_assignment_id            = coalesce(try(each.value.policy_assignment_id, null), try(local.assignment_ids[each.value.policy_assignment_key], null))
  exemption_category              = try(each.value.exemption_category, "Waiver")
  display_name                    = try(each.value.display_name, null)
  description                     = try(each.value.description, null)
  expires_on                      = try(each.value.expires_on, null)
  metadata                        = try(each.value.metadata, null) == null ? null : jsonencode(each.value.metadata)
  policy_definition_reference_ids = try(each.value.policy_definition_reference_ids, null)
}

resource "azurerm_subscription_policy_exemption" "subscription_exemption" {
  for_each = local.subscription_exemptions

  name                            = each.key
  subscription_id                 = each.value.subscription_id
  policy_assignment_id            = coalesce(try(each.value.policy_assignment_id, null), try(local.assignment_ids[each.value.policy_assignment_key], null))
  exemption_category              = try(each.value.exemption_category, "Waiver")
  display_name                    = try(each.value.display_name, null)
  description                     = try(each.value.description, null)
  expires_on                      = try(each.value.expires_on, null)
  metadata                        = try(each.value.metadata, null) == null ? null : jsonencode(each.value.metadata)
  policy_definition_reference_ids = try(each.value.policy_definition_reference_ids, null)
}

resource "azurerm_resource_group_policy_exemption" "rg_exemption" {
  for_each = local.resource_group_exemptions

  name                            = each.key
  resource_group_id               = each.value.resource_group_id
  policy_assignment_id            = coalesce(try(each.value.policy_assignment_id, null), try(local.assignment_ids[each.value.policy_assignment_key], null))
  exemption_category              = try(each.value.exemption_category, "Waiver")
  display_name                    = try(each.value.display_name, null)
  description                     = try(each.value.description, null)
  expires_on                      = try(each.value.expires_on, null)
  metadata                        = try(each.value.metadata, null) == null ? null : jsonencode(each.value.metadata)
  policy_definition_reference_ids = try(each.value.policy_definition_reference_ids, null)
}
