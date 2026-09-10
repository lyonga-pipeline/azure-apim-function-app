output "application_client_ids" {
  description = "App registration client IDs keyed by workload_identities key (use for TFC_AZURE_RUN_CLIENT_ID / ARM_CLIENT_ID)."
  value       = { for key, app in module.application : key => app.client_id }
}

output "application_object_ids" {
  description = "App registration object IDs keyed by workload_identities key."
  value       = { for key, app in module.application : key => app.object_id }
}

output "service_principal_object_ids" {
  description = "Service principal object IDs keyed by workload_identities key (use for RBAC on other scopes)."
  value       = { for key, sp in module.service_principal : key => sp.object_id }
}

output "federated_credential_ids" {
  description = "Federated identity credential resource IDs keyed `<identity_key>::<credential_key>`."
  value       = { for key, fic in azuread_application_federated_identity_credential.this : key => fic.id }
}

output "role_assignment_ids" {
  description = "SP role assignment resource IDs keyed `<identity_key>::<assignment_key>`."
  value       = { for key, ra in azurerm_role_assignment.this : key => ra.id }
}

output "operational_contracts" {
  description = "Declared workload-identity operational controls that are not provisioned here."
  value       = module.operational_contracts.contracts
}

output "manual_control_keys" {
  description = "Workload-identity controls deliberately left outside Terraform."
  value       = module.operational_contracts.manual_control_keys
}
