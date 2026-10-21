output "contract_version" {
  description = "Version of this blueprint's public consumer contract."
  value       = "1.0.0"
}

output "resource_group_names" {
  description = "Logical RG keys: network, security, application (app-rg), plus operations/data only when their optional services are approved."
  value       = module.resource_groups.group_names
}

output "resource_group_ids" {
  description = "Application-consumable RG IDs keyed by logical purpose."
  value       = module.resource_groups.group_ids
}

output "log_analytics_workspace_id" {
  description = "Approved LAW passthrough so application roots do not need platform output/state access."
  value       = var.platform.log_analytics_workspace_id
}

output "mandatory_tag_keys" {
  description = "Approved governance keys passed through by the adapter; standalone compositions default to the shared tag module's standard."
  value       = local.mandatory_tag_keys
}

output "spoke_virtual_network_id" {
  description = "Spoke VNet ARM resource ID."
  value       = module.network.id
}

output "subnet_ids" {
  description = "Subnet IDs keyed by stable logical input key, not generated Azure name."
  value       = local.subnet_ids
}

output "key_vault" {
  description = "Dedicated workload vault metadata; never secret contents."
  value = try({
    id                  = module.key_vault[0].id
    name                = module.key_vault[0].name
    uri                 = module.key_vault[0].uri
    private_endpoint_id = module.key_vault[0].private_endpoint_id
  }, null)
}

output "workload_identity" {
  description = "Attach this UAMI to the consuming application and select its client_id for SDK authentication."
  value = {
    id           = module.workload_identity.id
    client_id    = module.workload_identity.client_id
    principal_id = module.workload_identity.principal_id
  }
}

output "attachment_contract" {
  description = "Versioned intent for a separately authorized central attachment state. Resource IDs do not prove completed attachment or connectivity."
  value = {
    contract_version                 = "2.0.0"
    owner                            = "central-attachment-workspace"
    hub_virtual_network_id           = var.platform.hub_virtual_network_id
    spoke_virtual_network_id         = module.network.id
    spoke_virtual_network_name       = module.network.name
    spoke_resource_group_name        = module.resource_groups.group_names["network"]
    key_vault_private_dns_zone_id    = var.key_vault.enabled ? var.platform.key_vault_private_dns_zone_id : null
    storage_blob_private_dns_zone_id = length(local.enabled_storage_accounts) > 0 ? var.platform.storage_blob_private_dns_zone_id : null
    gateway_transit_enabled          = var.gateway_transit_enabled
    tags                             = module.tags.tags
    naming_context = {
      region      = var.location
      environment = var.environment
      domain      = var.domain
      appcode     = var.appcode
    }
    private_dns_zones = merge({ for key in ["key_vault"] : key => {
      name                  = "privatelink.vaultcore.azure.net"
      resource_group_name   = try(split("/", var.platform.key_vault_private_dns_zone_id)[4], "")
      registration_enabled  = false
      link_to_spoke_enabled = true
      } if var.key_vault.enabled
      }, { for key in ["storage_blob"] : key => {
        name                  = "privatelink.blob.core.windows.net"
        resource_group_name   = try(split("/", var.platform.storage_blob_private_dns_zone_id)[4], "")
        registration_enabled  = false
        link_to_spoke_enabled = true
      } if length(local.enabled_storage_accounts) > 0 }
    )
  }
}

output "diagnostic_ownership" {
  description = "Optional exact-resource registration for strict Terraform diagnostic ownership in platform-policy."
  value = {
    workspace_id = var.platform.log_analytics_workspace_id
    # Preserve the v1 vault-only registration fields; storage uses the per-target profiles below.
    log_categories         = var.key_vault.enabled ? ["AuditEvent"] : []
    terraform_resource_ids = [for vault in module.key_vault : vault.id if !contains(keys(var.diagnostics.existing_settings), "key_vault")]
    existing_setting_ids   = { for key, setting in var.diagnostics.existing_settings : key => setting.id }
    targets = { for key, id in local.diagnostic_targets : key => {
      target_resource_id = id
      owner              = contains(keys(var.diagnostics.existing_settings), key) ? "existing-resource-owner" : "this-workload-state"
      log_categories     = local.diagnostic_requirements[key].logs
      metric_categories  = local.diagnostic_requirements[key].metrics
    } }
  }
  depends_on = [terraform_data.capability_contract, terraform_data.reuse_contract]
}

output "security_baseline" {
  description = "Configuration evidence, not proof of runtime connectivity or policy compliance."
  value = {
    default_outbound_access_enabled = false
    egress_next_hop_ip              = var.egress_next_hop_ip
    key_vault_public_access         = try(module.key_vault[0].security_configuration.public_network_access_enabled, null)
    key_vault_rbac                  = try(module.key_vault[0].security_configuration.rbac_authorization_enabled, null)
    key_vault_purge_protection      = try(module.key_vault[0].security_configuration.purge_protection_enabled, null)
    flow_log_owner                  = "platform-policy"
    defender_owner                  = "platform-policy"
    inspection_address_prefixes     = local.inspection_address_prefixes
    gateway_bgp_propagation_enabled = false
    nsg_ids                         = { for key, nsg in module.network_security_groups : key => nsg.id }
    route_table_ids                 = { for key, route in module.route_tables : key => route.id }
    vault_role_assignment_ids       = try(module.key_vault[0].role_assignment_ids, {})
  }
}

output "environment_profile" {
  description = "Resolved production/non-production resilience and operational defaults; not a claim of an application SLO."
  value       = local.environment_profile
}

output "application_services" {
  description = "Consumer metadata for separately deployed mixed compute workloads. No instrumentation key or connection string is published here."
  value = {
    application_resource_group_name            = module.resource_groups.group_names["application"]
    application_insights_id                    = local.application_insights_id
    application_insights_name                  = local.application_insights_name
    application_insights_owner                 = !var.monitoring.enabled ? null : local.create_application_insights ? "this-workload-state" : "existing-resource-owner"
    telemetry_access_managed                   = local.manage_telemetry_access
    application_insights_configuration_managed = local.create_application_insights
    action_group_ids                           = local.action_group_ids
    created_action_group_ids                   = [for group in module.alert_contacts : group.id]
    failed_requests_alert_id                   = local.failed_requests_alert_id
    failed_requests_alert_owner                = !var.monitoring.alerts_enabled ? null : local.create_failed_requests_alert ? "this-workload-state" : "existing-resource-owner"
    storage = { for key, account in module.storage : key => {
      id                        = account.id, name = account.name, blob_endpoint = account.primary_blob_endpoint,
      private_endpoint_id       = module.storage_endpoints[key].id,
      replication_type          = local.storage_replication[key], delete_retention_days = local.storage_retention[key]
      diagnostic_resource_ids   = [account.id, "${account.id}/blobServices/default"]
      diagnostic_log_categories = ["StorageRead", "StorageWrite", "StorageDelete"]
    } }
    backup_registration_ids = { for key, protected in azurerm_backup_protected_vm.workload : key => protected.id }
  }
}

output "context" {
  description = "Non-secret workload context and shared mandatory tags for application consumers."
  value = {
    subscription_id = var.subscription_id
    tenant_id       = var.tenant_id
    environment     = var.environment
    location        = var.location
    appcode         = var.appcode
    domain          = var.domain
    tags            = module.tags.tags
  }
}
