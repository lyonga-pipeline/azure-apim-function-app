output "subscription_placement_ids" {
  description = "Management-group subscription-association IDs keyed by subscription logical name."
  value       = try(module.subscription_onboarding[0].subscription_placement_ids, {})
}

output "onboarded_subscription_ids" {
  description = "Subscription GUIDs onboarded by this workspace."
  value       = try(module.subscription_onboarding[0].onboarded_subscription_ids, {})
}

output "onboarded_subscription_resource_ids" {
  description = "Subscription resource IDs keyed by logical name."
  value       = try(module.subscription_onboarding[0].onboarded_subscription_resource_ids, {})
}

output "subscription_target_management_group_ids" {
  description = "Resolved target management group resource ID per onboarded subscription."
  value       = try(module.subscription_onboarding[0].subscription_target_management_group_ids, {})
}

output "baseline_role_assignment_ids" {
  description = "Subscription-scope baseline RBAC assignment IDs."
  value       = try(module.subscription_onboarding[0].baseline_role_assignment_ids, {})
}

output "app_role_assignment_ids" {
  description = "Subscription-scope app-specific RBAC assignment IDs."
  value       = try(module.subscription_onboarding[0].app_role_assignment_ids, {})
}

output "legacy_policy_removal_ids" {
  description = "Legacy subscription/resource-group-scope policy assignments currently imported and tracked for removal."
  value       = try(module.subscription_onboarding[0].legacy_policy_removal_ids, {})
}
