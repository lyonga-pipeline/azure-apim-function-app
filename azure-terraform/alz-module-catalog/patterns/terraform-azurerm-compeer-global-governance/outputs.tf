output "management_group_ids" {
  description = "Management group resource IDs keyed by management group key (from the management-groups module). Platform_Output_Contracts_IAC-10 governance_management_group_ids."
  value       = module.management_groups.management_group_ids
}

output "subscription_placement_ids" {
  description = "Management group subscription association IDs keyed `<management_group_key>-<subscription_id>`."
  value       = module.management_groups.subscription_association_ids
}

output "custom_policy_definition_ids" {
  description = "Custom Azure Policy definition IDs keyed by definition key."
  value       = module.policy.policy_definition_ids
}

output "custom_policy_set_definition_ids" {
  description = "Custom Azure Policy initiative (set definition) IDs keyed by initiative key. Platform_Output_Contracts_IAC-10 governance_policy_initiative_ids (this catalog bundles the baseline into one initiative rather than one per topic - see PATTERN-REFERENCE.md sec 1)."
  value       = module.policy.policy_set_definition_ids
}

output "management_group_policy_assignment_ids" {
  description = "IDs of the policy assignments made at management group scope, keyed by assignment key. Platform_Output_Contracts_IAC-10 governance_policy_assignment_ids (management group half)."
  value       = module.policy.management_group_assignment_ids
}

output "subscription_policy_assignment_ids" {
  description = "IDs of the policy assignments made at subscription scope, keyed by assignment key. Platform_Output_Contracts_IAC-10 governance_policy_assignment_ids (subscription half)."
  value       = module.policy.subscription_assignment_ids
}

output "custom_role_definition_ids" {
  description = "Governance-level custom role definition GUIDs, keyed by definition key (distinct from platform-authorization's custom_role_definition_ids - these are the roles governance itself owns)."
  value       = { for key, value in module.custom_role_definitions : key => value.id }
}

output "role_assignment_ids" {
  description = "IDs of the role assignments this pattern creates."
  value       = module.role_assignments.ids
}

output "management_group_budget_ids" {
  description = "IDs of the management-group-scoped consumption budgets this pattern creates, keyed by budget key."
  value       = { for key, value in azurerm_consumption_budget_management_group.management_group_budget : key => value.id }
}

output "mandatory_tag_keys" {
  description = "Tag keys enforced by the cmp-required-tags baseline policy (Platform_Output_Contracts_IAC-10 governance_mandatory_tag_keys) - re-published from policy_baseline.tf so every root and workload-spoke can validate against the same list without hand-copying it."
  value       = local.pb_required_tags
}
