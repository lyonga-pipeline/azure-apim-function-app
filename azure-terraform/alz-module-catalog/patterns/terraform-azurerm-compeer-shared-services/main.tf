module "shared_services" {
  source = "../terraform-azurerm-compeer-workload-spoke"

  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
  location                        = var.location
  environment                     = var.environment
  workload_tags                   = var.platform_tags
  resource_group                  = var.resource_group
  spoke_vnet                      = var.spoke_vnet
  hub_connection                  = var.hub_connection
  private_dns_zone_links          = var.private_dns_zone_links
  workload_identity               = var.platform_identity
  workload_key_vault              = var.platform_key_vault
  role_assignments                = var.role_assignments
  management_locks                = var.management_locks
  diagnostic_settings             = var.diagnostic_settings
  additional_scopes               = var.additional_scopes
  network_security_groups         = var.network_security_groups
  subnet_nsg_associations         = var.subnet_nsg_associations
  route_tables                    = var.route_tables
  subnet_route_table_associations = var.subnet_route_table_associations
}
