locals {
  enabled = try(var.spoke.enabled, false)

  management              = try(data.tfe_outputs.management[0].nonsensitive_values, {})
  connectivity            = try(data.tfe_outputs.connectivity[0].nonsensitive_values, {})
  governance              = try(data.tfe_outputs.governance[0].nonsensitive_values, {})
  private_dns_ids_by_name = { for key, id in try(local.connectivity.private_dns_zone_ids, {}) : lower(try(local.connectivity.private_dns_zone_names[key], split("/", id)[8])) => id }
  platform = {
    management_contract_version      = try(var.platform_inputs.management_contract_version, local.management.contract_version, "unset")
    connectivity_contract_version    = try(var.platform_inputs.connectivity_contract_version, local.connectivity.contract_version, "unset")
    log_analytics_workspace_id       = try(var.platform_inputs.log_analytics_workspace_id, local.management.log_analytics_workspace_id, "unset")
    hub_virtual_network_id           = try(var.platform_inputs.hub_virtual_network_id, local.connectivity.hub_virtual_network_id, "unset")
    hub_address_space                = try(var.platform_inputs.hub_address_space, local.connectivity.hub_virtual_network_address_space, [])
    key_vault_private_dns_zone_id    = coalesce(try(var.platform_inputs.key_vault_private_dns_zone_id, null), try(local.connectivity.key_vault_private_dns_zone_id, null), try(local.connectivity.private_dns_zone_ids.key_vault, null), lookup(local.private_dns_ids_by_name, "privatelink.vaultcore.azure.net", null), "unset")
    storage_blob_private_dns_zone_id = try(coalesce(try(var.platform_inputs.storage_blob_private_dns_zone_id, null), try(local.connectivity.storage_blob_private_dns_zone_id, null), try(local.connectivity.private_dns_zone_ids.storage_blob, null), lookup(local.private_dns_ids_by_name, "privatelink.blob.core.windows.net", null)), null)
    dns_server_ips                   = try(var.platform_inputs.dns_server_ips, local.connectivity.dns_server_ips, [])
    ddos_protection_plan_id          = try(var.platform_inputs.ddos_protection_plan_id, local.connectivity.ddos_protection_plan_id, null)
    mandatory_tag_keys               = try(var.platform_inputs.mandatory_tag_keys, local.governance.mandatory_tag_keys, [])
    # Disabled platform groups are not notification routes; never select a different audience implicitly.
    action_group_ids = try(var.platform_inputs.action_group_ids, try(local.management.action_group_enabled, true) == false ? {} : try(local.management.action_group_ids, {}))
  }

  spoke_contract = try({
    contract_version           = module.blueprint[0].contract_version
    context                    = module.blueprint[0].context
    resource_group_names       = module.blueprint[0].resource_group_names
    resource_group_ids         = module.blueprint[0].resource_group_ids
    log_analytics_workspace_id = module.blueprint[0].log_analytics_workspace_id
    mandatory_tag_keys         = module.blueprint[0].mandatory_tag_keys
    spoke_virtual_network_id   = module.blueprint[0].spoke_virtual_network_id
    subnet_ids                 = module.blueprint[0].subnet_ids
    key_vault                  = module.blueprint[0].key_vault
    workload_identity          = module.blueprint[0].workload_identity
    attachment_contract        = module.blueprint[0].attachment_contract
    diagnostic_ownership       = module.blueprint[0].diagnostic_ownership
    security_baseline          = module.blueprint[0].security_baseline
    environment_profile        = module.blueprint[0].environment_profile
    application_services       = module.blueprint[0].application_services
  }, null)
}
