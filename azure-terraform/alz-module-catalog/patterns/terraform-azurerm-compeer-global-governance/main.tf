# Every non-fixed management group name is <domain>-mg - one instance per
# key rather than the single front-door module, because each management
# group needs its OWN `domain` (there's no single "this root's identity"
# the way a resource-group-scoped pattern has). trimsuffix is a no-op for a
# key that's already the bare domain; it only matters for keys already
# written with the "-mg" suffix baked in.
module "naming_mg" {
  source      = "../../modules/terraform-azurerm-compeer-naming"
  for_each    = var.management_groups
  region      = coalesce(try(var.naming.region, null), "centralus")
  environment = try(var.naming.environment, "shared")
  domain      = trimsuffix(each.key, "-mg")
}

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

module "management_groups" {
  source = "../../modules/terraform-azurerm-compeer-management-groups"

  root_parent_management_group_id = local.root_parent_management_group_id

  management_groups = {
    for key, value in var.management_groups : key => {
      display_name     = coalesce(try(value.display_name, null), module.naming_mg[key].mg, key)
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

  role_assignment_inputs = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      scope = coalesce(
        try(assignment.scope, null),
        try(local.management_group_scope_ids[assignment.management_group_key], null)
      )
    })
  }

  # -----------------------------------------------------------------------
  # Everything below resolves management_group_key -> a concrete
  # management_group_id and drops the key before handing entries to
  # module.policy - that module has no concept of this pattern's MG catalog
  # (see modules/terraform-azurerm-compeer-policy's README "Boundary"
  # section). policy_definition_key / policy_set_definition_key are left
  # untouched: those resolve against sibling definitions/initiatives the
  # module itself creates in the same call, so the module keeps doing that
  # resolution internally. module.policy's variables are typed `any` (not a
  # strict object schema) specifically so this filter-then-merge works: real
  # policy parameters/policy_rule/metadata have a genuinely different
  # attribute key set per policy, and only `any` avoids a "cannot find a
  # common base type" module-boundary error across such a map.
  # -----------------------------------------------------------------------

  policy_definitions_input = {
    for k, v in merge(var.custom_policy_definitions, local.pb_definitions) : k => merge(
      { for ik, iv in v : ik => iv if ik != "management_group_key" && ik != "management_group_id" },
      { management_group_id = coalesce(try(v.management_group_id, null), try(local.management_group_scope_ids[v.management_group_key], null)) }
    )
  }

  policy_set_definitions_input = {
    for k, v in merge(var.custom_policy_set_definitions, local.pb_initiative) : k => merge(
      { for ik, iv in v : ik => iv if ik != "management_group_key" && ik != "management_group_id" },
      { management_group_id = coalesce(try(v.management_group_id, null), try(local.management_group_scope_ids[v.management_group_key], null)) }
    )
  }

  management_group_policy_assignments_input = {
    for k, v in merge(var.management_group_policy_assignments, local.pb_assignments) : k => merge(
      { for ik, iv in v : ik => iv if ik != "management_group_key" && ik != "management_group_id" && ik != "location" },
      {
        management_group_id = coalesce(try(v.management_group_id, null), try(local.management_group_scope_ids[v.management_group_key], null))
        location            = try(v.identity, null) == null ? null : try(v.location, var.policy_assignment_location)
      }
    )
  }

  subscription_policy_assignments_input = {
    for k, v in var.subscription_policy_assignments : k => merge(
      { for ik, iv in v : ik => iv if ik != "location" },
      { location = try(v.identity, null) == null ? null : try(v.location, var.policy_assignment_location) }
    )
  }
}

module "policy" {
  source = "../../modules/terraform-azurerm-compeer-policy"

  policy_definitions           = local.policy_definitions_input
  policy_set_definitions       = local.policy_set_definitions_input
  management_group_assignments = local.management_group_policy_assignments_input
  subscription_assignments     = local.subscription_policy_assignments_input
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

resource "azurerm_consumption_budget_management_group" "management_group_budget" {
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
