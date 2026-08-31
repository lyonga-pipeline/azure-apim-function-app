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

output "baseline_role_assignment_ids" {
  value = try(module.subscription_onboarding[0].baseline_role_assignment_ids, {})
}

output "app_role_assignment_ids" {
  value = try(module.subscription_onboarding[0].app_role_assignment_ids, {})
}
