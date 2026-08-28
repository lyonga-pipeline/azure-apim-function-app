output "management_group_ids" {
  value = local.enabled ? try(module.subscription_vending[0].management_group_ids, {}) : {
    for key, group in local.management_groups : key => try(group.management_group_id, null)
  }
}

output "subscription_catalog" {
  value = try(module.subscription_vending[0].subscription_catalog, {})
}

output "vended_subscription_ids" {
  value = try(module.subscription_vending[0].vended_subscription_ids, {})
}

output "vended_subscription_resource_ids" {
  value = try(module.subscription_vending[0].vended_subscription_resource_ids, {})
}

output "platform_management_subscription_id" {
  value = try(module.subscription_vending[0].vended_subscription_ids["platform_management"], null)
}

output "platform_connectivity_subscription_id" {
  value = try(module.subscription_vending[0].vended_subscription_ids["platform_connectivity"], null)
}

output "platform_identity_subscription_id" {
  value = try(module.subscription_vending[0].vended_subscription_ids["platform_identity"], null)
}

output "platform_security_subscription_id" {
  value = try(module.subscription_vending[0].vended_subscription_ids["platform_security"], null)
}
