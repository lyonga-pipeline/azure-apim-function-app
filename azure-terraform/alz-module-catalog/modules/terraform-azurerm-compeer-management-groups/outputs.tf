output "management_group_ids" {
  description = "Management group resource IDs keyed by module input key."
  value       = local.management_group_ids
}

output "management_group_names" {
  description = "Management group names keyed by module input key."
  value = merge(
    { for key, group in azurerm_management_group.external_parent : key => group.name },
    { for key, group in azurerm_management_group.root : key => group.name },
    { for key, group in azurerm_management_group.level_1 : key => group.name },
    { for key, group in azurerm_management_group.level_2 : key => group.name },
    { for key, group in azurerm_management_group.level_3 : key => group.name },
    { for key, group in azurerm_management_group.level_4 : key => group.name }
  )
}
