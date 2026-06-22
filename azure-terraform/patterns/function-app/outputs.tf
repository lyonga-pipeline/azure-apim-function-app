output "resource_group_name" {
  value = local.resource_group_name
}

output "resource_group_id" {
  value = local.resource_group_id
}

output "function_app_id" {
  value = module.function_app.id
}

output "function_app_name" {
  value = module.function_app.name
}

output "function_app_default_hostname" {
  value = module.function_app.default_hostname
}

output "identity_id" {
  value = local.identity_id
}

output "identity_principal_id" {
  value = local.identity_principal_id
}

output "storage_account_id" {
  value = local.storage_account_id
}

output "storage_account_name" {
  value = local.storage_account_name
}

output "key_vault_id" {
  value = local.key_vault_id
}

output "key_vault_uri" {
  value = local.key_vault_uri
}

output "application_insights_id" {
  value = local.application_insights_id
}

output "private_endpoint_ids" {
  value = { for key, value in module.private_endpoints : key => value.id }
}

output "diagnostic_setting_ids" {
  value = { for key, value in module.diagnostic_settings : key => value.id }
}

output "role_assignment_ids" {
  value = module.role_assignments.ids
}

