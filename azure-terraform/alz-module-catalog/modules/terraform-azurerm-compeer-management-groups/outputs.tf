output "management_group_ids" {
  description = "Management group resource IDs keyed by module input key."
  value       = local.management_group_ids
}

output "management_group_names" {
  description = "Management group names keyed by module input key."
  value = merge(
    { for key, group in azurerm_management_group.root : key => group.name },
    { for key, group in azurerm_management_group.level_1 : key => group.name },
    { for key, group in azurerm_management_group.level_2 : key => group.name },
    { for key, group in azurerm_management_group.level_3 : key => group.name },
    { for key, group in azurerm_management_group.level_4 : key => group.name },
    { for key, group in azurerm_management_group.level_5 : key => group.name }
  )
}

output "management_groups" {
  description = "Management group attributes keyed by module input key for downstream policy, RBAC, and subscription placement."
  value = merge(
    {
      for key, group in azurerm_management_group.root : key => {
        id                         = group.id
        name                       = group.name
        display_name               = group.display_name
        parent_management_group_id = group.parent_management_group_id
      }
    },
    {
      for key, group in azurerm_management_group.level_1 : key => {
        id                         = group.id
        name                       = group.name
        display_name               = group.display_name
        parent_management_group_id = group.parent_management_group_id
      }
    },
    {
      for key, group in azurerm_management_group.level_2 : key => {
        id                         = group.id
        name                       = group.name
        display_name               = group.display_name
        parent_management_group_id = group.parent_management_group_id
      }
    },
    {
      for key, group in azurerm_management_group.level_3 : key => {
        id                         = group.id
        name                       = group.name
        display_name               = group.display_name
        parent_management_group_id = group.parent_management_group_id
      }
    },
    {
      for key, group in azurerm_management_group.level_4 : key => {
        id                         = group.id
        name                       = group.name
        display_name               = group.display_name
        parent_management_group_id = group.parent_management_group_id
      }
    },
    {
      for key, group in azurerm_management_group.level_5 : key => {
        id                         = group.id
        name                       = group.name
        display_name               = group.display_name
        parent_management_group_id = group.parent_management_group_id
      }
    }
  )
}

output "subscription_association_ids" {
  description = "Management group subscription association IDs keyed by management group and subscription."
  value       = { for key, association in azurerm_management_group_subscription_association.this : key => association.id }
}
