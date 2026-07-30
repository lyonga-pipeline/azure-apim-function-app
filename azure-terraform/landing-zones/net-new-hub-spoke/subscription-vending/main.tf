locals {
  billing_account_name     = trimspace(var.billing_account_name == null ? "" : var.billing_account_name)
  billing_profile_name     = trimspace(var.billing_profile_name == null ? "" : var.billing_profile_name)
  invoice_section_name     = trimspace(var.invoice_section_name == null ? "" : var.invoice_section_name)
  default_billing_scope_id = trimspace(var.default_billing_scope_id == null ? "" : var.default_billing_scope_id)

  billing_scope_id_from_parts = (
    local.billing_account_name != "" &&
    local.billing_profile_name != "" &&
    local.invoice_section_name != ""
    ? "/providers/Microsoft.Billing/billingAccounts/${local.billing_account_name}/billingProfiles/${local.billing_profile_name}/invoiceSections/${local.invoice_section_name}"
    : ""
  )

  effective_default_billing_scope_id = local.default_billing_scope_id != "" ? local.default_billing_scope_id : local.billing_scope_id_from_parts

  enabled_management_groups = {
    for key, group in var.management_groups : key => group
    if try(group.enabled, true)
  }

  management_group_ids = {
    for key, group in local.enabled_management_groups : key => (
      try(trimspace(group.management_group_id), "") == "" ?
      "/providers/Microsoft.Management/managementGroups/${key}" :
      startswith(trimspace(group.management_group_id), "/providers/Microsoft.Management/managementGroups/") ?
      trimspace(group.management_group_id) :
      "/providers/Microsoft.Management/managementGroups/${trimspace(group.management_group_id)}"
    )
  }

  enabled_subscriptions = {
    for key, subscription in var.subscriptions : key => subscription
    if var.vending_enabled && try(subscription.enabled, true)
  }

  subscription_inputs = {
    for key, subscription in local.enabled_subscriptions : key => {
      alias             = coalesce(try(subscription.alias, null), key)
      subscription_name = coalesce(try(subscription.subscription_name, null), key)
      billing_scope_id = (
        trimspace(try(subscription.billing_scope_id, null) == null ? "" : subscription.billing_scope_id) != ""
        ? trimspace(subscription.billing_scope_id)
        : local.effective_default_billing_scope_id
      )
      management_group_key = subscription.management_group_key
      management_group_id  = lookup(local.management_group_ids, subscription.management_group_key, null)
      workload             = try(subscription.workload, "Production")
      tags                 = merge(var.default_tags, coalesce(try(subscription.tags, null), {}))
    }
  }

  missing_billing_scope_keys = [
    for key, subscription in local.subscription_inputs : key
    if subscription.billing_scope_id == null || trimspace(subscription.billing_scope_id) == ""
  ]

  placeholder_billing_scope_keys = [
    for key, subscription in local.subscription_inputs : key
    if can(regex("(<replace|\\.\\.\\.)", subscription.billing_scope_id))
  ]

  unknown_management_group_keys = sort(distinct([
    for _, subscription in local.enabled_subscriptions : subscription.management_group_key
    if !contains(keys(local.management_group_ids), subscription.management_group_key)
  ]))

  invalid_workload_keys = [
    for key, subscription in local.subscription_inputs : key
    if !contains(["Production", "DevTest"], subscription.workload)
  ]

  subscription_contract_valid = (
    length(local.enabled_subscriptions) > 0 &&
    length(local.missing_billing_scope_keys) == 0 &&
    length(local.placeholder_billing_scope_keys) == 0 &&
    length(local.unknown_management_group_keys) == 0 &&
    length(local.invalid_workload_keys) == 0
  )

  subscription_resource_inputs = local.subscription_contract_valid ? local.subscription_inputs : {}
}

resource "terraform_data" "subscription_vending_contract" {
  count = var.vending_enabled ? 1 : 0

  input = {
    enabled_subscription_keys = sort(keys(local.enabled_subscriptions))
    management_group_keys     = sort(keys(local.management_group_ids))
  }

  lifecycle {
    precondition {
      condition     = length(local.enabled_subscriptions) > 0
      error_message = "vending_enabled is true, but no subscriptions are enabled in var.subscriptions."
    }

    precondition {
      condition     = length(local.missing_billing_scope_keys) == 0
      error_message = "Subscription vending requires default_billing_scope_id or per-subscription billing_scope_id for: ${join(", ", local.missing_billing_scope_keys)}."
    }

    precondition {
      condition     = length(local.placeholder_billing_scope_keys) == 0
      error_message = "Subscription vending still contains placeholder or truncated billing scope values for: ${join(", ", local.placeholder_billing_scope_keys)}."
    }

    precondition {
      condition     = length(local.unknown_management_group_keys) == 0
      error_message = "Subscription vending references unknown or disabled management group keys: ${join(", ", local.unknown_management_group_keys)}."
    }

    precondition {
      condition     = length(local.invalid_workload_keys) == 0
      error_message = "Subscription workload must be Production or DevTest for: ${join(", ", local.invalid_workload_keys)}."
    }
  }
}

resource "azurerm_subscription" "this" {
  for_each = local.subscription_resource_inputs

  alias             = each.value.alias
  subscription_name = each.value.subscription_name
  billing_scope_id  = each.value.billing_scope_id
  workload          = each.value.workload
  tags              = each.value.tags

  timeouts {
    create = try(var.subscription_timeouts.create, null)
    read   = try(var.subscription_timeouts.read, null)
    update = try(var.subscription_timeouts.update, null)
    delete = try(var.subscription_timeouts.delete, null)
  }

  depends_on = [terraform_data.subscription_vending_contract]
}

resource "azurerm_management_group_subscription_association" "this" {
  for_each = azurerm_subscription.this

  management_group_id = local.subscription_inputs[each.key].management_group_id
  subscription_id     = "/subscriptions/${each.value.subscription_id}"
}
