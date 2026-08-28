output "alz" { value = module.alz }
output "custom_role_definition_ids" { value = { for key, role in module.custom_role_definitions : key => role.id } }
output "policy_definition_ids" { value = module.policy_baseline.policy_definition_ids }
output "policy_set_definition_ids" { value = module.policy_baseline.policy_set_definition_ids }
output "management_group_policy_assignment_ids" { value = module.policy_baseline.management_group_assignment_ids }
