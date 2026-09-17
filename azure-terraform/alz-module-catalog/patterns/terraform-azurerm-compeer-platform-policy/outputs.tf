output "custom_policy_definition_ids" {
  description = "Custom Azure Policy definition IDs keyed by definition key."
  value       = module.policy.policy_definition_ids
}

output "custom_policy_set_definition_ids" {
  description = "Custom Azure Policy initiative IDs keyed by initiative key."
  value       = module.policy.policy_set_definition_ids
}

output "management_group_policy_assignment_ids" {
  description = "IDs of the policy assignments made at management group scope, keyed by assignment key."
  value       = module.policy.management_group_assignment_ids
}

output "subscription_policy_assignment_ids" {
  description = "IDs of the policy assignments made at subscription scope, keyed by assignment key."
  value       = module.policy.subscription_assignment_ids
}

output "resource_group_policy_assignment_ids" {
  description = "IDs of the policy assignments made at resource group scope, keyed by assignment key."
  value       = module.policy.resource_group_assignment_ids
}

output "policy_exemption_ids" {
  description = "IDs of the policy exemptions this pattern creates, keyed by exemption key."
  value       = module.policy.policy_exemption_ids
}

output "remediation_assignment_ids" {
  description = "Management-group-scoped policy assignment IDs whose key is prefixed \"rem-\" (a DINE remediation assignment), keyed with that prefix stripped."
  value = {
    for k, v in module.policy.management_group_assignment_ids : trimprefix(k, "rem-") => v
    if startswith(k, "rem-")
  }
}

output "remediation_assignment_principal_ids" {
  description = "SystemAssigned principal IDs of the remediation assignments - grant these the roles their DINE policies require."
  value = {
    for k, v in module.policy.management_group_assignment_principal_ids : trimprefix(k, "rem-") => v
    if startswith(k, "rem-")
  }
}
