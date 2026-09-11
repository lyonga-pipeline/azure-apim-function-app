output "ids" {
  description = "Role management policy resource IDs keyed by policies key."
  value       = { for key, policy in azurerm_role_management_policy.this : key => policy.id }
}

output "names" {
  value = { for key, policy in azurerm_role_management_policy.this : key => policy.name }
}
