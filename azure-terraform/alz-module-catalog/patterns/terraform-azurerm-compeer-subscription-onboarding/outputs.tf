output "subscription_placement_ids" {
  description = "Management-group subscription-association IDs keyed by subscription logical name."
  value       = { for key, a in azurerm_management_group_subscription_association.placement : key => a.id }
}

output "onboarded_subscription_ids" {
  description = "Subscription GUIDs onboarded by this workspace, keyed by logical name."
  value       = { for key, s in var.subscriptions : key => s.subscription_id }
}

output "onboarded_subscription_resource_ids" {
  description = "Subscription resource IDs (/subscriptions/<guid>) keyed by logical name."
  value       = { for key, s in var.subscriptions : key => "/subscriptions/${s.subscription_id}" }
}

output "subscription_target_management_group_ids" {
  description = "Resolved target management group resource ID per subscription."
  value       = local.subscription_target_mg_ids
}

output "baseline_role_assignment_ids" {
  description = "Subscription-scope baseline RBAC assignment IDs."
  value       = module.baseline_role_assignments.ids
}

output "app_role_assignment_ids" {
  description = "Subscription-scope app-specific RBAC assignment IDs."
  value       = module.app_role_assignments.ids
}
