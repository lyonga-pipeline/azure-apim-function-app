output "custom_policy_definition_ids" {
  value = module.policy.policy_definition_ids
}

output "custom_policy_set_definition_ids" {
  value = module.policy.policy_set_definition_ids
}

output "management_group_policy_assignment_ids" {
  value = module.policy.management_group_assignment_ids
}

output "subscription_policy_assignment_ids" {
  value = module.policy.subscription_assignment_ids
}

output "resource_group_policy_assignment_ids" {
  value = module.policy.resource_group_assignment_ids
}

output "policy_exemption_ids" {
  value = module.policy.policy_exemption_ids
}

output "remediation_assignment_ids" {
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
