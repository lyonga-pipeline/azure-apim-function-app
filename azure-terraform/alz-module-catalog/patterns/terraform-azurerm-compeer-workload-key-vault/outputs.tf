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
  value       = try(module.private_endpoint["default"].id, null)
}

output "private_endpoint_configuration" {
  description = "Non-secret observed parent-owned endpoint wiring; does not prove live DNS or endpoint approval."
  value = try({
    subnet_id            = module.private_endpoint["default"].subnet_id
    target_resource_id   = module.private_endpoint["default"].private_service_connection[0].private_connection_resource_id
    subresource_names    = module.private_endpoint["default"].private_service_connection[0].subresource_names
    private_dns_zone_ids = [for config in module.private_endpoint["default"].private_dns_zone_configs : config.private_dns_zone_id]
  }, null)
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

output "private_endpoints" {
  description = "Observed endpoint configuration keyed by the caller's stable keys; does not assert approval or live DNS."
  value = { for key, endpoint in module.private_endpoint : key => {
    id                    = endpoint.id
    subnet_id             = endpoint.subnet_id
    target_resource_id    = endpoint.private_service_connection[0].private_connection_resource_id
    private_dns_zone_ids  = [for config in endpoint.private_dns_zone_configs : config.private_dns_zone_id]
    network_interface_ids = endpoint.network_interface_ids
  } }
}

output "key_ids" {
  description = "Versioned IDs of optional service-generated keys; no private key material is returned."
  value       = module.keys.ids
}

output "key_versionless_ids" {
  description = "Versionless key URIs for services that support automatic adoption of rotated keys."
  value       = module.keys.versionless_ids
}

output "metric_alert_ids" {
  description = "Optional availability, latency and saturation alerts; existing action groups remain externally owned."
  value       = { for key, alert in module.metric_alerts : key => alert.id }
}
