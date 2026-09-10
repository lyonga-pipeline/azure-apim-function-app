locals {
  # A group is "top-level" when it has no parent_key. Its Azure parent is either
  # a per-group parent_management_group_id, or the module-level
  # root_parent_management_group_id, or null (the tenant root group).
  root_groups = {
    for key, group in var.management_groups : key => group
    if try(group.parent_key, null) == null
  }

  top_level_groups = local.root_groups

  level_1_groups = {
    for key, group in var.management_groups : key => group
    if contains(keys(local.top_level_groups), try(group.parent_key, null) == null ? "" : group.parent_key)
  }

  level_2_groups = {
    for key, group in var.management_groups : key => group
    if contains(keys(local.level_1_groups), group.parent_key == null ? "" : group.parent_key)
  }

  level_3_groups = {
    for key, group in var.management_groups : key => group
    if contains(keys(local.level_2_groups), group.parent_key == null ? "" : group.parent_key)
  }

  level_4_groups = {
    for key, group in var.management_groups : key => group
    if contains(keys(local.level_3_groups), group.parent_key == null ? "" : group.parent_key)
  }

  level_5_groups = {
    for key, group in var.management_groups : key => group
    if contains(keys(local.level_4_groups), group.parent_key == null ? "" : group.parent_key)
  }

  level_1_parent_ids = { for key, group in azurerm_management_group.root : key => group.id }

  level_2_parent_ids = merge(
    local.level_1_parent_ids,
    { for key, group in azurerm_management_group.level_1 : key => group.id }
  )

  level_3_parent_ids = merge(
    local.level_2_parent_ids,
    { for key, group in azurerm_management_group.level_2 : key => group.id }
  )

  level_4_parent_ids = merge(
    local.level_3_parent_ids,
    { for key, group in azurerm_management_group.level_3 : key => group.id }
  )

  level_5_parent_ids = merge(
    local.level_4_parent_ids,
    { for key, group in azurerm_management_group.level_4 : key => group.id }
  )

  management_group_ids = merge(
    local.level_1_parent_ids,
    { for key, group in azurerm_management_group.level_1 : key => group.id },
    { for key, group in azurerm_management_group.level_2 : key => group.id },
    { for key, group in azurerm_management_group.level_3 : key => group.id },
    { for key, group in azurerm_management_group.level_4 : key => group.id },
    { for key, group in azurerm_management_group.level_5 : key => group.id }
  )

  placed_management_group_keys = setunion(
    toset(keys(local.top_level_groups)),
    toset(keys(local.level_1_groups)),
    toset(keys(local.level_2_groups)),
    toset(keys(local.level_3_groups)),
    toset(keys(local.level_4_groups)),
    toset(keys(local.level_5_groups))
  )

  subscription_association_list = flatten([
    for management_group_key, group in var.management_groups : [
      for subscription_id in try(group.subscription_ids, []) : {
        key                  = "${management_group_key}-${replace(subscription_id, "/", "_")}"
        management_group_key = management_group_key
        subscription_id      = subscription_id
      }
    ] if contains(local.placed_management_group_keys, management_group_key)
  ])

  subscription_associations = {
    for association in local.subscription_association_list : association.key => association
  }
}

# Externally parented top-level groups were previously a separate resource; they
# are now plain root groups whose parent is resolved per-group.
moved {
  from = azurerm_management_group.external_parent
  to   = azurerm_management_group.root
}

resource "azurerm_management_group" "root" {
  for_each = local.root_groups

  name         = each.key
  display_name = coalesce(try(each.value.display_name, null), each.key)
  parent_management_group_id = (
    try(each.value.parent_management_group_id, null) != null
    ? each.value.parent_management_group_id
    : var.root_parent_management_group_id
  )
}

resource "azurerm_management_group" "level_1" {
  for_each = local.level_1_groups

  name                       = each.key
  display_name               = coalesce(try(each.value.display_name, null), each.key)
  parent_management_group_id = local.level_1_parent_ids[each.value.parent_key]

  depends_on = [azurerm_management_group.root]
}

resource "azurerm_management_group" "level_2" {
  for_each = local.level_2_groups

  name                       = each.key
  display_name               = coalesce(try(each.value.display_name, null), each.key)
  parent_management_group_id = local.level_2_parent_ids[each.value.parent_key]

  depends_on = [azurerm_management_group.level_1]
}

resource "azurerm_management_group" "level_3" {
  for_each = local.level_3_groups

  name                       = each.key
  display_name               = coalesce(try(each.value.display_name, null), each.key)
  parent_management_group_id = local.level_3_parent_ids[each.value.parent_key]

  depends_on = [azurerm_management_group.level_2]
}

resource "azurerm_management_group" "level_4" {
  for_each = local.level_4_groups

  name                       = each.key
  display_name               = coalesce(try(each.value.display_name, null), each.key)
  parent_management_group_id = local.level_4_parent_ids[each.value.parent_key]

  depends_on = [azurerm_management_group.level_3]
}

resource "azurerm_management_group" "level_5" {
  for_each = local.level_5_groups

  name                       = each.key
  display_name               = coalesce(try(each.value.display_name, null), each.key)
  parent_management_group_id = local.level_5_parent_ids[each.value.parent_key]

  depends_on = [azurerm_management_group.level_4]
}

resource "azurerm_management_group_subscription_association" "this" {
  for_each = local.subscription_associations

  management_group_id = local.management_group_ids[each.value.management_group_key]
  subscription_id     = each.value.subscription_id
}
