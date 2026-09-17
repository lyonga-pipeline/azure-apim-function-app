output "custom_policy_definition_ids" {
  description = "Custom Azure Policy definition IDs keyed by definition key."
  value       = try(module.policy[0].custom_policy_definition_ids, {})
}

output "custom_policy_set_definition_ids" {
  description = "Custom Azure Policy initiative IDs keyed by initiative key."
  value       = try(module.policy[0].custom_policy_set_definition_ids, {})
}

output "management_group_policy_assignment_ids" {
  description = "IDs of the policy assignments made at management group scope, keyed by assignment key."
  value       = try(module.policy[0].management_group_policy_assignment_ids, {})
}

output "subscription_policy_assignment_ids" {
  description = "IDs of the policy assignments made at subscription scope, keyed by assignment key."
  value       = try(module.policy[0].subscription_policy_assignment_ids, {})
}

output "resource_group_policy_assignment_ids" {
  description = "IDs of the policy assignments made at resource group scope, keyed by assignment key."
  value       = try(module.policy[0].resource_group_policy_assignment_ids, {})
}

output "policy_exemption_ids" {
  description = "IDs of the policy exemptions this pattern creates, keyed by exemption key."
  value       = try(module.policy[0].policy_exemption_ids, {})
}

output "remediation_assignment_ids" {
  description = "Management-group-scoped policy assignment IDs that are DINE remediation assignments, keyed with the \"rem-\" prefix stripped."
  value       = try(module.policy[0].remediation_assignment_ids, {})
}

output "remediation_assignment_principal_ids" {
  description = "SystemAssigned principal IDs of the remediation assignments - grant these the roles their DINE policies require."
  value       = try(module.policy[0].remediation_assignment_principal_ids, {})
}
