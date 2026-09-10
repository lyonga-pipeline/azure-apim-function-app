output "group_object_ids" {
  description = "Entra security group object IDs keyed by rbac_groups key (feed these to subscription / workload RBAC)."
  value       = { for key, group in module.rbac_groups : key => group.object_id }
}

output "group_ids" {
  description = "Entra security group resource IDs keyed by rbac_groups key."
  value       = { for key, group in module.rbac_groups : key => group.id }
}

output "group_display_names" {
  description = "Entra security group display names keyed by rbac_groups key."
  value       = { for key, group in module.rbac_groups : key => group.display_name }
}

output "custom_role_definition_ids" {
  description = "Custom role definition GUIDs keyed by custom_role_definitions key."
  value       = { for key, role in module.custom_role_definitions : key => role.role_definition_id }
}

output "role_assignment_ids" {
  description = "Role assignment resource IDs keyed by role_assignments key."
  value       = module.role_assignments.ids
}

output "operational_contracts" {
  description = "Declared identity / RBAC operational controls that are not provisioned here."
  value       = module.operational_contracts.contracts
}

output "manual_control_keys" {
  description = "Operational controls deliberately left outside Terraform (see operational_contracts notes)."
  value       = module.operational_contracts.manual_control_keys
}
