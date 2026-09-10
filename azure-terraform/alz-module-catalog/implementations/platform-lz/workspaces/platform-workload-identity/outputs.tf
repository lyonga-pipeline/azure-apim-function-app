output "application_client_ids" {
  description = "App registration client IDs keyed by identity key. Wire into HCP workspace TFC_AZURE_RUN_CLIENT_ID via platform-iac-foundation."
  value       = try(module.workload_identity[0].application_client_ids, {})
}

output "service_principal_object_ids" {
  value = try(module.workload_identity[0].service_principal_object_ids, {})
}

output "federated_credential_ids" {
  value = try(module.workload_identity[0].federated_credential_ids, {})
}

output "role_assignment_ids" {
  value = try(module.workload_identity[0].role_assignment_ids, {})
}

output "operational_contracts" {
  value = try(module.workload_identity[0].operational_contracts, {})
}

output "manual_control_keys" {
  value = try(module.workload_identity[0].manual_control_keys, [])
}
