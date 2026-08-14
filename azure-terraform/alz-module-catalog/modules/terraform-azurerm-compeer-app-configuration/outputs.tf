/**
## Azure App Configuration Attributes
*/
output "app_config_id" {
  description = "The App Configuration ID."
  value       = local.configuration_store_id
}

output "app_config_endpoint" {
  description = "The URL of the App Configuration."
  value       = local.app_config_endpoint
}

output "app_config_feature_id" {
  description = "The App Configuration Feature ID"
  value       = local.app_config_feature_id
}

output "app_config_key_id" {
  description = "The App Configuration Key ID"
  value       = local.app_config_key_id
}