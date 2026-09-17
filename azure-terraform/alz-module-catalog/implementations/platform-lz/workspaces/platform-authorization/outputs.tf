output "group_object_ids" {
  description = "Entra security group object IDs keyed by rbac_groups key. Consumed by subscription-onboarding, workload-spoke, and privileged-access."
  value       = try(module.authorization[0].group_object_ids, {})
}

output "group_display_names" {
  value = try(module.authorization[0].group_display_names, {})
}

output "custom_role_definition_ids" {
  value = try(module.authorization[0].custom_role_definition_ids, {})
}

output "role_assignment_ids" {
  value = try(module.authorization[0].role_assignment_ids, {})
}

output "operational_contracts" {
  value = try(module.authorization[0].operational_contracts, {})
}

output "manual_control_keys" {
  description = "Identity / RBAC controls tracked here but deliberately not Terraform-managed."
  value       = try(module.authorization[0].manual_control_keys, [])
}

output "contract_version" {
  description = "Platform_Output_Contracts_IAC-10 identity_contract_version (this workspace covers IAM-01/02 of that contract; domain controllers live in platform-directory-services, shared managed identities in platform-identity-security)."
  value       = "0.1.0"
}
