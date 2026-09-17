output "management_group_ids" {
  description = "Management group IDs keyed by governance catalog key. Platform_Output_Contracts_IAC-10 governance_management_group_ids."
  value       = try(module.governance[0].management_group_ids, {})
}

output "custom_policy_definition_ids" {
  description = "Custom Azure Policy definition IDs keyed by definition key."
  value       = try(module.governance[0].custom_policy_definition_ids, {})
}

output "custom_policy_set_definition_ids" {
  description = "Custom Azure Policy initiative IDs keyed by initiative key. Platform_Output_Contracts_IAC-10 governance_policy_initiative_ids."
  value       = try(module.governance[0].custom_policy_set_definition_ids, {})
}

output "management_group_policy_assignment_ids" {
  description = "IDs of the policy assignments made at management group scope. Platform_Output_Contracts_IAC-10 governance_policy_assignment_ids (management group half)."
  value       = try(module.governance[0].management_group_policy_assignment_ids, {})
}

output "subscription_policy_assignment_ids" {
  description = "IDs of the policy assignments made at subscription scope. Platform_Output_Contracts_IAC-10 governance_policy_assignment_ids (subscription half)."
  value       = try(module.governance[0].subscription_policy_assignment_ids, {})
}

output "custom_role_definition_ids" {
  description = "Governance-level custom role definition GUIDs, keyed by definition key."
  value       = try(module.governance[0].custom_role_definition_ids, {})
}

output "role_assignment_ids" {
  description = "IDs of the role assignments this pattern creates."
  value       = try(module.governance[0].role_assignment_ids, {})
}

output "management_group_budget_ids" {
  description = "IDs of the management-group-scoped consumption budgets this pattern creates."
  value       = try(module.governance[0].management_group_budget_ids, {})
}

output "subscription_placement_ids" {
  description = "Management group subscription association IDs keyed `<management_group_key>-<subscription_id>`."
  value       = try(module.governance[0].subscription_placement_ids, {})
}

output "mandatory_tag_keys" {
  description = "Platform_Output_Contracts_IAC-10 governance_mandatory_tag_keys - consumed by every root's tag validation and by workload-spoke's spoke_mandatory_tag_keys passthrough."
  value       = try(module.governance[0].mandatory_tag_keys, [])
}

output "contract_version" {
  description = "Platform_Output_Contracts_IAC-10 governance_contract_version."
  value       = "0.1.0"
}
