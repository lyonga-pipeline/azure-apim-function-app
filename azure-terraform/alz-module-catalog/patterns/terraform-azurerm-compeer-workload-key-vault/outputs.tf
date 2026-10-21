output "id" {
  description = "Vault ARM resource ID. No secret values are published."
  value       = module.vault.id
}

output "name" {
  description = "Observed vault name."
  value       = module.vault.name
}

output "uri" {
  description = "Vault URI; clients use managed identity and private DNS to access it."
  value       = module.vault.vault_uri
}

output "private_endpoint_id" {
  description = "Private endpoint resource ID."
  value       = module.private_endpoint.id
}

output "private_endpoint_configuration" {
  description = "Non-secret observed parent-owned endpoint wiring; does not prove live DNS or endpoint approval."
  value = {
    subnet_id            = module.private_endpoint.subnet_id
    target_resource_id   = module.private_endpoint.private_service_connection[0].private_connection_resource_id
    subresource_names    = module.private_endpoint.private_service_connection[0].subresource_names
    private_dns_zone_ids = [for config in module.private_endpoint.private_dns_zone_configs : config.private_dns_zone_id]
  }
}

output "role_assignment_ids" {
  description = "Vault-scoped reader/operator assignments keyed by stable logical identifiers."
  value       = module.roles.ids
}

output "diagnostic_setting_id" {
  description = "AuditEvent/AllMetrics diagnostic setting targeting the central LAW."
  value       = var.diagnostics.existing_setting == null ? try(module.diagnostics[0].id, null) : var.diagnostics.existing_setting.id
  depends_on  = [terraform_data.diagnostic_reuse_contract]
}

output "diagnostic_ownership" {
  description = "Register this target in platform-policy if strict Terraform-only diagnostic ownership is required."
  value = {
    terraform_resource_ids = var.diagnostics.existing_setting == null ? [module.vault.id] : []
    log_categories         = ["AuditEvent"]
    workspace_id           = var.log_analytics_workspace_id
  }
}

output "security_configuration" {
  description = "Observed vault settings exported by the bundled base Key Vault helper. A registry replacement must expose the same security_configuration output."
  value       = module.vault.security_configuration
}

output "role_assignments" {
  description = "Observed vault-scoped assignments; contains no credentials."
  value       = module.roles.assignments
}
