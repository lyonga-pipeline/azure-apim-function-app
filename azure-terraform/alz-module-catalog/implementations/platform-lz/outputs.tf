output "management_group_ids" {
  value = try(module.global_governance[0].management_group_ids, {})
}

output "subscription_vending" {
  value = try(module.subscription_vending[0], null)
}

output "platform_management" {
  value = try({
    resource_group_name        = module.platform_management[0].resource_group_name
    log_analytics_workspace_id = module.platform_management[0].log_analytics_workspace_id
    action_group_id            = module.platform_management[0].action_group_id
    defender_soc_posture       = module.platform_management[0].defender_soc_posture
  }, null)
}

output "platform_connectivity" {
  value = try({
    hub_resource_group_name  = module.platform_connectivity[0].hub_resource_group_name
    hub_virtual_network_id   = module.platform_connectivity[0].hub_virtual_network_id
    subnet_ids               = module.platform_connectivity[0].subnet_ids
    private_dns_zone_ids     = module.platform_connectivity[0].private_dns_zone_ids
    palo_alto_route_contract = module.platform_connectivity[0].palo_alto_route_contract
    dns_resolution_contract  = module.platform_connectivity[0].dns_resolution_contract
  }, null)
}

output "platform_identity" {
  value = try({
    resource_group_name             = module.platform_identity[0].resource_group_name
    platform_identity_ids           = module.platform_identity[0].platform_identity_ids
    platform_identity_principal_ids = module.platform_identity[0].platform_identity_principal_ids
    key_vault_id                    = module.platform_identity[0].key_vault_id
    key_vault_name                  = module.platform_identity[0].key_vault_name
  }, null)
}

output "platform_hybrid_connectivity" {
  value = try(module.platform_hybrid_connectivity[0], null)
}

output "palo_alto_hub" {
  value = try(module.palo_alto_hub[0], null)
}

output "cloudflare_edge" {
  value = try(module.cloudflare_edge[0], null)
}
