output "management_group_ids" {
  description = "Normalized management group IDs from the vending catalog."
  value       = local.management_group_ids
}

output "subscription_catalog" {
  description = "Non-sensitive subscription catalog summary."
  value = {
    for key, subscription in var.subscriptions : key => {
      subscription_name    = coalesce(try(subscription.subscription_name, null), key)
      alias                = coalesce(try(subscription.alias, null), key)
      management_group_key = subscription.management_group_key
      enabled              = try(subscription.enabled, true)
      workload             = try(subscription.workload, "Production")
    }
  }
}

output "vended_subscription_ids" {
  description = "Subscription GUIDs created by this root."
  value = {
    for key, subscription in azurerm_subscription.this : key => subscription.subscription_id
  }
}

output "vended_subscription_resource_ids" {
  description = "Azure resource IDs for subscriptions created by this root."
  value = {
    for key, subscription in azurerm_subscription.this : key => "/subscriptions/${subscription.subscription_id}"
  }
}

output "subscription_management_group_association_ids" {
  description = "Management group association IDs for vended subscriptions."
  value = {
    for key, association in azurerm_management_group_subscription_association.this : key => association.id
  }
}

output "subscription_role_assignment_ids" {
  description = "Subscription-scope RBAC assignment IDs created for vended subscriptions."
  value       = module.subscription_role_assignments.ids
}
