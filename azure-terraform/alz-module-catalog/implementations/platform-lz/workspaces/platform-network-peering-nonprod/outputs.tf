output "contract_version" {
  value       = "1.0.0"
  description = "Environment attachment consumer contract."
}
output "attachments" {
  value       = try(module.attachments[0].attachments, {})
  description = "Owned peering/DNS child IDs, never ownership of their VNet parents."
}
output "environment" {
  value       = local.environment
  description = "Fixed state boundary."
}
output "allowed_environments" {
  value       = var.allowed_environments
  description = "Approved real producer environments, not relabelled to the state boundary."
}
