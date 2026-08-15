locals {
  subscription_vending_enabled         = try(var.subscription_vending.enabled, false)
  global_governance_enabled            = try(var.global_governance.enabled, false)
  platform_management_enabled          = try(var.platform_management.enabled, false)
  platform_connectivity_enabled        = try(var.platform_connectivity.enabled, false)
  platform_identity_enabled            = try(var.platform_identity.enabled, false)
  platform_hybrid_connectivity_enabled = try(var.platform_hybrid_connectivity.enabled, false)
  palo_alto_hub_enabled                = try(var.palo_alto_hub.enabled, false)
  cloudflare_edge_enabled              = try(var.cloudflare_edge.enabled, false)
  network_peering_enabled              = try(var.network_peering.enabled, false)
  workload_spoke_enabled               = try(var.workload_spoke.enabled, false)

  management_subscription_id   = try(var.platform_management.subscription_id, var.execution_subscription_id)
  connectivity_subscription_id = try(var.platform_connectivity.subscription_id, var.execution_subscription_id)
  identity_subscription_id     = try(var.platform_identity.subscription_id, var.execution_subscription_id)
  hybrid_subscription_id       = try(var.platform_hybrid_connectivity.subscription_id, local.connectivity_subscription_id)

  global_management_group_ids = try(module.global_governance[0].management_group_ids, {})
  connectivity_outputs        = try(module.platform_connectivity[0], null)
  management_outputs          = try(module.platform_management[0], null)
}

module "subscription_vending" {
  source = "../../patterns/terraform-azurerm-compeer-subscription-vending"
  count  = local.subscription_vending_enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id               = var.execution_subscription_id
  tenant_id                     = var.tenant_id
  vending_enabled               = try(var.subscription_vending.vending_enabled, false)
  default_billing_scope_id      = try(var.subscription_vending.default_billing_scope_id, try(var.subscription_vending.billing_scope, null))
  billing_account_name          = try(var.subscription_vending.billing_account_name, null)
  billing_profile_name          = try(var.subscription_vending.billing_profile_name, null)
  invoice_section_name          = try(var.subscription_vending.invoice_section_name, null)
  default_tags                  = merge(try(var.platform_tags.additional_tags, {}), try(var.subscription_vending.default_tags, {}))
  management_groups             = try(var.subscription_vending.management_groups, {})
  subscriptions                 = try(var.subscription_vending.subscriptions, {})
  subscription_role_assignments = try(var.subscription_vending.subscription_role_assignments, {})
  subscription_timeouts         = try(var.subscription_vending.subscription_timeouts, {})
}

module "global_governance" {
  source = "../../patterns/terraform-azurerm-compeer-global-governance"
  count  = local.global_governance_enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id                     = var.execution_subscription_id
  root_management_group_id            = try(var.global_governance.root_management_group_id, null)
  management_groups                   = try(var.global_governance.management_groups, {})
  subscription_placements             = try(var.global_governance.subscription_placements, {})
  policy_assignment_location          = try(var.global_governance.policy_assignment_location, var.location)
  custom_policy_definitions           = try(var.global_governance.custom_policy_definitions, {})
  custom_policy_set_definitions       = try(var.global_governance.custom_policy_set_definitions, {})
  management_group_policy_assignments = try(var.global_governance.management_group_policy_assignments, {})
  subscription_policy_assignments     = try(var.global_governance.subscription_policy_assignments, {})
  custom_role_definitions             = try(var.global_governance.custom_role_definitions, {})
  role_assignments                    = try(var.global_governance.role_assignments, {})
  management_group_budgets            = try(var.global_governance.management_group_budgets, {})
}

module "platform_management" {
  source = "../../patterns/terraform-azurerm-compeer-platform-management"
  count  = local.platform_management_enabled ? 1 : 0

  providers = {
    azurerm = azurerm.management
  }

  subscription_id                       = local.management_subscription_id
  location                              = var.location
  environment                           = var.environment
  platform_tags                         = merge(var.platform_tags, try(var.platform_management.platform_tags, {}))
  resource_group                        = try(var.platform_management.resource_group, null)
  log_analytics                         = try(var.platform_management.log_analytics, null)
  action_group                          = try(var.platform_management.action_group, null)
  platform_storage_accounts             = try(var.platform_management.platform_storage_accounts, {})
  recovery_services_vaults              = try(var.platform_management.recovery_services_vaults, {})
  resource_provider_registrations       = try(var.platform_management.resource_provider_registrations, {})
  role_assignments                      = try(var.platform_management.role_assignments, {})
  subscription_activity_log_diagnostics = try(var.platform_management.subscription_activity_log_diagnostics, null)
  entra_diagnostic_settings             = try(var.platform_management.entra_diagnostic_settings, null)
  subscription_budgets                  = try(var.platform_management.subscription_budgets, {})
  management_locks                      = try(var.platform_management.management_locks, {})
  additional_lock_scopes                = try(var.platform_management.additional_lock_scopes, {})
  defender_plans                        = try(var.platform_management.defender_plans, {})
  security_contact                      = try(var.platform_management.security_contact, null)
  security_center_settings              = try(var.platform_management.security_center_settings, {})
  defender_soc_posture                  = try(var.platform_management.defender_soc_posture, { enabled = false })
}

module "platform_connectivity" {
  source = "../../patterns/terraform-azurerm-compeer-platform-connectivity"
  count  = local.platform_connectivity_enabled ? 1 : 0

  providers = {
    azurerm = azurerm.connectivity
  }

  subscription_id                 = local.connectivity_subscription_id
  location                        = var.location
  environment                     = var.environment
  platform_tags                   = merge(var.platform_tags, try(var.platform_connectivity.platform_tags, {}))
  resource_group                  = try(var.platform_connectivity.resource_group, null)
  hub_vnet                        = try(var.platform_connectivity.hub_vnet, null)
  palo_alto                       = try(var.platform_connectivity.palo_alto, { enabled = false })
  dns_resolution                  = try(var.platform_connectivity.dns_resolution, { enabled = false })
  network_security_groups         = try(var.platform_connectivity.network_security_groups, {})
  subnet_nsg_associations         = try(var.platform_connectivity.subnet_nsg_associations, {})
  route_tables                    = try(var.platform_connectivity.route_tables, {})
  subnet_route_table_associations = try(var.platform_connectivity.subnet_route_table_associations, {})
  public_ips                      = try(var.platform_connectivity.public_ips, {})
  load_balancers                  = try(var.platform_connectivity.load_balancers, {})
  private_dns_zones               = try(var.platform_connectivity.private_dns_zones, {})
  role_assignments                = try(var.platform_connectivity.role_assignments, {})
  management_locks                = try(var.platform_connectivity.management_locks, {})
  diagnostic_settings             = try(var.platform_connectivity.diagnostic_settings, {})
  additional_scopes               = try(var.platform_connectivity.additional_scopes, {})
}

module "platform_identity" {
  source = "../../patterns/terraform-azurerm-compeer-platform-identity"
  count  = local.platform_identity_enabled ? 1 : 0

  providers = {
    azurerm = azurerm.identity
  }

  subscription_id            = local.identity_subscription_id
  tenant_id                  = var.tenant_id
  location                   = var.location
  environment                = var.environment
  platform_tags              = merge(var.platform_tags, try(var.platform_identity.platform_tags, {}))
  resource_group             = try(var.platform_identity.resource_group, null)
  platform_identities        = try(var.platform_identity.platform_identities, {})
  key_vault                  = try(var.platform_identity.key_vault, null)
  key_vault_private_endpoint = try(var.platform_identity.key_vault_private_endpoint, null)
  log_analytics_workspace_id = try(var.platform_identity.log_analytics_workspace_id, try(module.platform_management[0].log_analytics_workspace_id, null))
  diagnostics                = try(var.platform_identity.diagnostics, null)
  identity_role_assignments  = try(var.platform_identity.identity_role_assignments, {})
  external_role_assignments  = try(var.platform_identity.external_role_assignments, {})
  management_locks           = try(var.platform_identity.management_locks, {})
  additional_lock_scopes     = try(var.platform_identity.additional_lock_scopes, {})
}

module "platform_hybrid_connectivity" {
  source = "../../patterns/terraform-azurerm-compeer-platform-hybrid-connectivity"
  count  = local.platform_hybrid_connectivity_enabled ? 1 : 0

  providers = {
    azurerm = azurerm.hybrid
  }

  subscription_id          = local.hybrid_subscription_id
  location                 = var.location
  environment              = var.environment
  platform_tags            = merge(var.platform_tags, try(var.platform_hybrid_connectivity.platform_tags, {}))
  resource_group           = try(var.platform_hybrid_connectivity.resource_group, null)
  expressroute_posture     = try(var.platform_hybrid_connectivity.expressroute_posture, { enabled = false })
  expressroute_circuits    = try(var.platform_hybrid_connectivity.expressroute_circuits, {})
  gateway_public_ips       = try(var.platform_hybrid_connectivity.gateway_public_ips, try(var.platform_hybrid_connectivity.expressroute_gateway_public_ips, {}))
  expressroute_gateway     = try(var.platform_hybrid_connectivity.expressroute_gateway, null)
  expressroute_connections = try(var.platform_hybrid_connectivity.expressroute_connections, {})
}

module "palo_alto_hub" {
  source = "../../patterns/terraform-azurerm-compeer-palo-alto-hub"
  count  = local.palo_alto_hub_enabled ? 1 : 0

  providers = {
    azurerm = azurerm.connectivity
  }

  enabled                   = try(var.palo_alto_hub.enabled, false)
  resource_group_name       = try(var.palo_alto_hub.resource_group_name, try(module.platform_connectivity[0].hub_resource_group_name, null))
  location                  = var.location
  tags                      = merge(try(var.platform_tags.additional_tags, {}), try(var.palo_alto_hub.tags, try(var.palo_alto_hub.platform_tags, {})))
  bootstrap_storage_account = try(var.palo_alto_hub.bootstrap_storage_account, try(var.palo_alto_hub.bootstrap, null))
  public_ips                = try(var.palo_alto_hub.public_ips, {})
  network_interfaces        = try(var.palo_alto_hub.network_interfaces, {})
  load_balancers            = try(var.palo_alto_hub.load_balancers, {})
  virtual_machines          = try(var.palo_alto_hub.virtual_machines, {})
}

module "cloudflare_edge" {
  source = "../../patterns/terraform-cloudflare-compeer-edge-baseline"
  count  = local.cloudflare_edge_enabled ? 1 : 0

  providers = {
    cloudflare = cloudflare
  }

  enabled  = try(var.cloudflare_edge.enabled, false)
  zones    = try(var.cloudflare_edge.zones, {})
  records  = try(var.cloudflare_edge.records, {})
  rulesets = try(var.cloudflare_edge.rulesets, {})
}

module "network_peering" {
  source = "../../patterns/terraform-azurerm-compeer-network-peering"
  count  = local.network_peering_enabled ? 1 : 0

  providers = {
    azurerm.hub   = azurerm.connectivity
    azurerm.spoke = azurerm.workload
  }

  tenant_id                            = try(var.network_peering.tenant_id, var.tenant_id)
  hub_subscription_id                  = try(var.network_peering.hub_subscription_id, local.connectivity_subscription_id)
  spoke_subscription_id                = try(var.network_peering.spoke_subscription_id, var.execution_subscription_id)
  use_tfe_outputs                      = try(var.network_peering.use_tfe_outputs, false)
  tfe_organization                     = try(var.network_peering.tfe_organization, null)
  platform_connectivity_workspace_name = try(var.network_peering.platform_connectivity_workspace_name, null)
  workload_spoke_workspace_name        = try(var.network_peering.workload_spoke_workspace_name, null)
  hub_resource_group_name              = try(var.network_peering.hub_resource_group_name, try(module.platform_connectivity[0].hub_resource_group_name, null))
  hub_virtual_network_name             = try(var.network_peering.hub_virtual_network_name, try(module.platform_connectivity[0].hub_virtual_network_name, null))
  hub_virtual_network_id               = try(var.network_peering.hub_virtual_network_id, try(module.platform_connectivity[0].hub_virtual_network_id, null))
  spoke_resource_group_name            = try(var.network_peering.spoke_resource_group_name, null)
  spoke_virtual_network_name           = try(var.network_peering.spoke_virtual_network_name, null)
  spoke_virtual_network_id             = try(var.network_peering.spoke_virtual_network_id, null)
  peering_name_prefix                  = try(var.network_peering.peering_name_prefix, "platform-lz")
  hub_to_spoke                         = try(var.network_peering.hub_to_spoke, {})
  spoke_to_hub                         = try(var.network_peering.spoke_to_hub, {})
  private_dns_zone_resource_group_name = try(var.network_peering.private_dns_zone_resource_group_name, try(module.platform_connectivity[0].hub_resource_group_name, null))
  private_dns_zones                    = try(var.network_peering.private_dns_zones, {})
  tags                                 = merge(try(var.platform_tags.additional_tags, {}), try(var.network_peering.tags, {}))
}

module "workload_spoke" {
  source = "../../patterns/terraform-azurerm-compeer-workload-spoke"
  count  = local.workload_spoke_enabled ? 1 : 0

  providers = {
    azurerm = azurerm.workload
  }

  subscription_id         = try(var.workload_spoke.subscription_id, var.execution_subscription_id)
  location                = var.location
  environment             = var.environment
  workload_tags           = merge(var.platform_tags, try(var.workload_spoke.workload_tags, try(var.workload_spoke.platform_tags, {})))
  resource_group          = try(var.workload_spoke.resource_group, null)
  spoke_vnet              = try(var.workload_spoke.spoke_vnet, null)
  hub_connection          = try(var.workload_spoke.hub_connection, local.platform_connectivity_enabled ? { hub_virtual_network_id = module.platform_connectivity[0].hub_virtual_network_id } : null)
  private_dns_zone_links  = try(var.workload_spoke.private_dns_zone_links, {})
  role_assignments        = try(var.workload_spoke.role_assignments, {})
  management_locks        = try(var.workload_spoke.management_locks, {})
  diagnostic_settings     = try(var.workload_spoke.diagnostic_settings, {})
  additional_scopes       = try(var.workload_spoke.additional_scopes, {})
  network_security_groups = try(var.workload_spoke.network_security_groups, {})
  route_tables            = try(var.workload_spoke.route_tables, {})
}
