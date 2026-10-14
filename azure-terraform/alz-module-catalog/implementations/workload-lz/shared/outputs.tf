output "spoke" {
  description = "Public workload contract; null while deployment is disabled."
  value = try({
    contract_version         = module.blueprint[0].contract_version
    context                  = module.blueprint[0].context
    resource_group_names     = module.blueprint[0].resource_group_names
    spoke_virtual_network_id = module.blueprint[0].spoke_virtual_network_id
    subnet_ids               = module.blueprint[0].subnet_ids
    key_vault                = module.blueprint[0].key_vault
    workload_identity        = module.blueprint[0].workload_identity
    attachment_contract      = module.blueprint[0].attachment_contract
    diagnostic_ownership     = module.blueprint[0].diagnostic_ownership
    security_baseline        = module.blueprint[0].security_baseline
    environment_profile      = module.blueprint[0].environment_profile
    application_services     = module.blueprint[0].application_services
  }, null)
}
