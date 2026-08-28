output "application_client_ids" { value = { for key, app in module.ad_application : key => app.client_id } }
output "application_object_ids" { value = { for key, app in module.ad_application : key => app.object_id } }
output "service_principal_object_ids" { value = { for key, sp in module.service_principal : key => sp.object_id } }
output "federated_credential_ids" { value = { for key, credential in azuread_application_federated_identity_credential.this : key => credential.id } }
