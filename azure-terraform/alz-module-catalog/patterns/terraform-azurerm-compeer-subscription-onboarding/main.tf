locals {
  # Normalize the resolved MG catalog to full resource IDs.
  management_group_ids = {
    for key, value in var.management_group_ids : key => (
      startswith(trimspace(value), "/providers/Microsoft.Management/managementGroups/")
      ? trimspace(value)
      : "/providers/Microsoft.Management/managementGroups/${trimspace(value)}"
    )
  }

  # Per-subscription target MG resource ID.
  subscription_target_mg_ids = {
    for key, s in var.subscriptions : key => (
      s.target_management_group_id != null
      ? (
        startswith(trimspace(s.target_management_group_id), "/providers/Microsoft.Management/managementGroups/")
        ? trimspace(s.target_management_group_id)
        : "/providers/Microsoft.Management/managementGroups/${trimspace(s.target_management_group_id)}"
      )
      : lookup(local.management_group_ids, s.target_management_group_key, null)
    )
  }

  unresolved_target_keys = sort([
    for key, id in local.subscription_target_mg_ids : key if id == null
  ])

  baseline_principal_group_keys = [
    for assignment in values(var.baseline_role_assignments) : assignment.principal_group_key
    if try(assignment.principal_group_key, null) != null
  ]

  app_principal_group_keys = flatten([
    for subscription in values(var.subscriptions) : [
      for assignment in values(subscription.app_role_assignments) : assignment.principal_group_key
      if try(assignment.principal_group_key, null) != null
    ]
  ])

  unresolved_principal_group_keys = sort(tolist(setsubtract(
    toset(concat(local.baseline_principal_group_keys, local.app_principal_group_keys)),
    toset(keys(var.group_object_ids))
  )))

  unresolved_legacy_removal_subscription_keys = sort([
    for r in values(var.legacy_policy_removals) : r.subscription_key
    if !contains(keys(var.subscriptions), r.subscription_key)
  ])

  contract_valid = (
    length(local.unresolved_target_keys) == 0 &&
    length(local.unresolved_principal_group_keys) == 0 &&
    length(local.unresolved_legacy_removal_subscription_keys) == 0
  )

  subscriptions = local.contract_valid ? var.subscriptions : {}

  unresolved_principal_placeholder = "00000000-0000-0000-0000-000000000000"

  # Baseline RBAC: cartesian of (subscription that opts in) x (baseline entry).
  baseline_assignment_inputs = {
    for pair in flatten([
      for sub_key, s in local.subscriptions : [
        for ra_key, ra in var.baseline_role_assignments : {
          key = "${sub_key}::baseline::${ra_key}"
          value = {
            name                             = null
            scope                            = "/subscriptions/${s.subscription_id}"
            principal_id                     = try(ra.principal_id, null) != null ? ra.principal_id : lookup(var.group_object_ids, ra.principal_group_key, local.unresolved_principal_placeholder)
            role_definition_name             = ra.role_definition_name
            role_definition_id               = ra.role_definition_id
            principal_type                   = try(ra.principal_group_key, null) != null ? "Group" : ra.principal_type
            description                      = coalesce(ra.description, "Platform baseline RBAC for onboarded subscription ${sub_key}")
            condition                        = ra.condition
            condition_version                = ra.condition_version
            skip_service_principal_aad_check = ra.skip_service_principal_aad_check
          }
        }
        if s.apply_baseline_rbac
      ]
    ]) : pair.key => pair.value
  }

  # Legacy policy assignments to remove during onboarding - see
  # var.legacy_policy_removals' description for the full rationale (MG-move
  # already handles inherited policy correctly; this handles the kind that
  # doesn't move with it: direct subscription/RG-scope assignments).
  legacy_removals     = local.contract_valid ? var.legacy_policy_removals : {}
  legacy_sub_removals = { for k, r in local.legacy_removals : k => r if r.scope_type == "subscription" }
  legacy_rg_removals  = { for k, r in local.legacy_removals : k => r if r.scope_type == "resource_group" }
  legacy_removal_subscription_ids = {
    for k, r in local.legacy_removals : k => local.subscriptions[r.subscription_key].subscription_id
  }

  # App-specific RBAC declared inline per subscription.
  app_assignment_inputs = {
    for pair in flatten([
      for sub_key, s in local.subscriptions : [
        for ra_key, ra in s.app_role_assignments : {
          key = "${sub_key}::app::${ra_key}"
          value = {
            name                             = ra.name
            scope                            = "/subscriptions/${s.subscription_id}"
            principal_id                     = try(ra.principal_id, null) != null ? ra.principal_id : lookup(var.group_object_ids, ra.principal_group_key, local.unresolved_principal_placeholder)
            role_definition_name             = ra.role_definition_name
            role_definition_id               = ra.role_definition_id
            principal_type                   = try(ra.principal_group_key, null) != null ? "Group" : ra.principal_type
            description                      = ra.description
            condition                        = ra.condition
            condition_version                = ra.condition_version
            skip_service_principal_aad_check = ra.skip_service_principal_aad_check
          }
        }
      ]
    ]) : pair.key => pair.value
  }
}

resource "terraform_data" "onboarding_contract" {
  input = {
    subscription_keys = sort(keys(var.subscriptions))
    default_tags      = var.default_tags
  }

  lifecycle {
    precondition {
      condition = local.contract_valid
      error_message = join(" ", compact([
        length(local.unresolved_target_keys) > 0 ? "subscriptions reference management group keys not present in management_group_ids: ${join(", ", local.unresolved_target_keys)}." : "",
        length(local.unresolved_principal_group_keys) > 0 ? "RBAC assignments reference principal_group_key values not present in group_object_ids: ${join(", ", local.unresolved_principal_group_keys)}." : "",
        length(local.unresolved_legacy_removal_subscription_keys) > 0 ? "legacy_policy_removals reference subscription_key values not present in subscriptions: ${join(", ", local.unresolved_legacy_removal_subscription_keys)}." : "",
      ]))
    }
  }
}

# Move each already-existing subscription from the Tenant Root Group to its
# target management group. Azure enforces single-MG membership, so creating this
# association relocates the subscription; destroying it returns the subscription
# to the root group.
resource "azurerm_management_group_subscription_association" "this" {
  for_each = local.subscriptions

  management_group_id = local.subscription_target_mg_ids[each.key]
  subscription_id     = "/subscriptions/${each.value.subscription_id}"

  depends_on = [terraform_data.onboarding_contract]
}

module "baseline_role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.baseline_assignment_inputs

  depends_on = [azurerm_management_group_subscription_association.this]
}

module "app_role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.app_assignment_inputs

  depends_on = [azurerm_management_group_subscription_association.this]
}

# =============================================================================
# Legacy policy assignment removal (var.legacy_policy_removals)
#
# These two resources are deliberately never given real state by an `import`
# block IN THIS FILE — Terraform only allows `import` blocks in the root
# module, and this pattern is always consumed as a child module (see every
# `implementations/*/workspaces/*` root). The root that calls this pattern is
# responsible for its own `import { to = module.<this>.azurerm_..._policy_assignment.legacy_removal[key] ... }`
# blocks — see the "Legacy policy removal" section of
# implementations/platform-lz/workspaces/platform-subscription-onboarding/main.tf
# for the reference implementation, and this pattern's README for the full
# two-phase import-then-destroy workflow.
#
# Once imported (by the consuming root), these declarations are deliberately
# left as the ONLY place the assignment is declared with real arguments — so
# removing an entry from var.legacy_policy_removals (after import) makes the
# next plan propose a clean, reviewable destroy instead of an implicit one.
# =============================================================================

resource "azurerm_subscription_policy_assignment" "legacy_removal" {
  for_each = local.legacy_sub_removals

  name                 = each.value.assignment_name
  subscription_id      = "/subscriptions/${local.legacy_removal_subscription_ids[each.key]}"
  policy_definition_id = each.value.policy_definition_id

  depends_on = [azurerm_management_group_subscription_association.this]
}

resource "azurerm_resource_group_policy_assignment" "legacy_removal" {
  for_each = local.legacy_rg_removals

  name                 = each.value.assignment_name
  resource_group_id    = "/subscriptions/${local.legacy_removal_subscription_ids[each.key]}/resourceGroups/${each.value.resource_group_name}"
  policy_definition_id = each.value.policy_definition_id

  depends_on = [azurerm_management_group_subscription_association.this]
}
