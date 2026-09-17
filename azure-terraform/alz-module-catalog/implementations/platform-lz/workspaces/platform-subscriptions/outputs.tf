output "management_group_ids" {
  description = "Normalized management group IDs from the vending catalog, or (when subscription vending is disabled) resolved from the static local.management_groups map instead."
  value = local.enabled ? try(module.subscription_vending[0].management_group_ids, {}) : {
    for key, group in local.management_groups : key => try(group.management_group_id, null)
  }
}

output "subscription_catalog" {
  description = "Non-sensitive subscription catalog summary."
  value       = try(module.subscription_vending[0].subscription_catalog, {})
}

output "vended_subscription_ids" {
  description = "Subscription GUIDs created by this workspace."
  value       = try(module.subscription_vending[0].vended_subscription_ids, {})
}

output "vended_subscription_resource_ids" {
  description = "Azure resource IDs for subscriptions created by this workspace."
  value       = try(module.subscription_vending[0].vended_subscription_resource_ids, {})
}

output "subscription_management_group_association_ids" {
  description = "Management group association IDs for vended subscriptions."
  value       = try(module.subscription_vending[0].subscription_management_group_association_ids, {})
}

output "subscription_role_assignment_ids" {
  description = "Subscription-scope RBAC assignment IDs created for vended subscriptions."
  value       = try(module.subscription_vending[0].subscription_role_assignment_ids, {})
}

output "platform_management_subscription_id" {
  description = "Convenience accessor: vended_subscription_ids[\"platform_management\"], or null if that key wasn't vended here."
  value       = try(module.subscription_vending[0].vended_subscription_ids["platform_management"], null)
}

output "platform_connectivity_subscription_id" {
  description = "Convenience accessor: vended_subscription_ids[\"platform_connectivity\"], or null if that key wasn't vended here."
  value       = try(module.subscription_vending[0].vended_subscription_ids["platform_connectivity"], null)
}

output "platform_identity_subscription_id" {
  description = "Convenience accessor: vended_subscription_ids[\"platform_identity\"], or null if that key wasn't vended here."
  value       = try(module.subscription_vending[0].vended_subscription_ids["platform_identity"], null)
}

output "platform_security_subscription_id" {
  description = "Convenience accessor: vended_subscription_ids[\"platform_security\"], or null if that key wasn't vended here."
  value       = try(module.subscription_vending[0].vended_subscription_ids["platform_security"], null)
}
