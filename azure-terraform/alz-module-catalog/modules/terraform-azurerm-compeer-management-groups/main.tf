locals {
  external_parent_groups = {
    for key, group in var.management_groups : key => group
    if try(group.parent_management_group_id, null) != null
  }

  root_groups = {
    for key, group in var.management_groups : key => group
    if try(group.parent_key, null) == null && try(group.parent_management_group_id, null) == null
  }

  level_1_groups = {
    for key, group in var.management_groups : key => group
    if contains(keys(local.root_groups), try(group.parent_key, ""))
  }

  level_2_groups = {
    for key, group in var.management_groups : key => group
    if contains(keys(local.level_1_groups), try(group.parent_key, ""))
  }

  level_3_groups = {
    for key, group in var.management_groups : key => group
    if contains(keys(local.level_2_groups), try(group.parent_key, ""))
  }

  level_4_groups = {
    for key, group in var.management_groups : key => group
    if contains(keys(local.level_3_groups), try(group.parent_key, ""))
  }

  level_1_parent_ids = merge(
    { for key, group in azurerm_management_group.external_parent : key => group.id },
    { for key, group in azurerm_management_group.root : key => group.id }
  )

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

  management_group_ids = merge(
    local.level_1_parent_ids,
    { for key, group in azurerm_management_group.level_1 : key => group.id },
    { for key, group in azurerm_management_group.level_2 : key => group.id },
    { for key, group in azurerm_management_group.level_3 : key => group.id },
    { for key, group in azurerm_management_group.level_4 : key => group.id }
  )

  subscription_association_list = flatten([
    for management_group_key, group in var.management_groups : [
      for subscription_id in try(group.subscription_ids, []) : {
        key                  = "${management_group_key}-${replace(subscription_id, "/", "_")}"
        management_group_key = management_group_key
        subscription_id      = subscription_id
      }
    ]
  ])

  subscription_associations = {
    for association in local.subscription_association_list : association.key => association
  }
}

resource "azurerm_management_group" "external_parent" {
  for_each = local.external_parent_groups

  name                       = each.key
  display_name               = coalesce(try(each.value.display_name, null), each.key)
  parent_management_group_id = each.value.parent_management_group_id
}

resource "azurerm_management_group" "root" {
  for_each = local.root_groups

  name                       = each.key
  display_name               = coalesce(try(each.value.display_name, null), each.key)
  parent_management_group_id = var.root_parent_management_group_id
}

resource "azurerm_management_group" "level_1" {
  for_each = local.level_1_groups

  name                       = each.key
  display_name               = coalesce(try(each.value.display_name, null), each.key)
  parent_management_group_id = local.level_1_parent_ids[each.value.parent_key]

  depends_on = [azurerm_management_group.root, azurerm_management_group.external_parent]
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

resource "azurerm_management_group_subscription_association" "this" {
  for_each = local.subscription_associations

  management_group_id = local.management_group_ids[each.value.management_group_key]
  subscription_id     = each.value.subscription_id
}
