# =============================================================================
# Resource-group-scope assignments + policy exemptions (all three scopes).
#
# The platform-policy pattern is the single home for policy exemptions and
# remediation. The stand-alone policy-baseline module is retired - use this
# pattern instead.
# =============================================================================

resource "azurerm_resource_group_policy_assignment" "this" {
  for_each = var.resource_group_policy_assignments

  name              = try(each.value.name, each.key)
  resource_group_id = each.value.resource_group_id
  policy_definition_id = coalesce(
    try(each.value.policy_definition_id, null),
    try(each.value.policy_set_definition_id, null),
    try(local.policy_definition_ids[each.value.policy_definition_key], null),
    try(local.policy_set_definition_ids[each.value.policy_set_definition_key], null),
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
}

locals {
  _all_assignment_ids = merge(
    { for k, v in azurerm_management_group_policy_assignment.this : k => v.id },
    { for k, v in azurerm_subscription_policy_assignment.this : k => v.id },
    { for k, v in azurerm_resource_group_policy_assignment.this : k => v.id },
  )

  mg_exemptions  = { for k, v in var.policy_exemptions : k => v if v.scope_type == "management_group" }
  sub_exemptions = { for k, v in var.policy_exemptions : k => v if v.scope_type == "subscription" }
  rg_exemptions  = { for k, v in var.policy_exemptions : k => v if v.scope_type == "resource_group" }
}

resource "azurerm_management_group_policy_exemption" "this" {
  for_each = local.mg_exemptions

  name                            = each.key
  management_group_id             = coalesce(try(each.value.management_group_id, null), try(local.management_group_scope_ids[each.value.management_group_key], null))
  policy_assignment_id            = coalesce(try(each.value.policy_assignment_id, null), try(local._all_assignment_ids[each.value.policy_assignment_key], null))
  exemption_category              = try(each.value.exemption_category, "Waiver")
  display_name                    = try(each.value.display_name, null)
  description                     = try(each.value.description, null)
  expires_on                      = try(each.value.expires_on, null)
  metadata                        = try(each.value.metadata, null) == null ? null : jsonencode(each.value.metadata)
  policy_definition_reference_ids = try(each.value.policy_definition_reference_ids, null)
}

resource "azurerm_subscription_policy_exemption" "this" {
  for_each = local.sub_exemptions

  name                            = each.key
  subscription_id                 = each.value.subscription_id
  policy_assignment_id            = coalesce(try(each.value.policy_assignment_id, null), try(local._all_assignment_ids[each.value.policy_assignment_key], null))
  exemption_category              = try(each.value.exemption_category, "Waiver")
  display_name                    = try(each.value.display_name, null)
  description                     = try(each.value.description, null)
  expires_on                      = try(each.value.expires_on, null)
  metadata                        = try(each.value.metadata, null) == null ? null : jsonencode(each.value.metadata)
  policy_definition_reference_ids = try(each.value.policy_definition_reference_ids, null)
}

resource "azurerm_resource_group_policy_exemption" "this" {
  for_each = local.rg_exemptions

  name                            = each.key
  resource_group_id               = each.value.resource_group_id
  policy_assignment_id            = coalesce(try(each.value.policy_assignment_id, null), try(local._all_assignment_ids[each.value.policy_assignment_key], null))
  exemption_category              = try(each.value.exemption_category, "Waiver")
  display_name                    = try(each.value.display_name, null)
  description                     = try(each.value.description, null)
  expires_on                      = try(each.value.expires_on, null)
  metadata                        = try(each.value.metadata, null) == null ? null : jsonencode(each.value.metadata)
  policy_definition_reference_ids = try(each.value.policy_definition_reference_ids, null)
}
