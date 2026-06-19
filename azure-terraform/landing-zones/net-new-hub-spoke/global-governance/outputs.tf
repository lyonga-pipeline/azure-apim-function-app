output "management_group_ids" {
  value = { for key, value in azurerm_management_group.this : key => value.id }
}

output "subscription_placement_ids" {
  value = { for key, value in azurerm_management_group_subscription_association.this : key => value.id }
}

