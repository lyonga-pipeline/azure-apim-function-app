output "spoke" {
  description = "Public contract for the central attachment owner, application roots and read-only live verifier."
  value = try({
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
