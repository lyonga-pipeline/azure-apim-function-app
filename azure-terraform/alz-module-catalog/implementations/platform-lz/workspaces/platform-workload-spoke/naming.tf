# =============================================================================
# Naming standard (design-doc Appendix F). A workload spoke names itself from
# its workload token. Current standard: VNet =
# <workload>-<region>-<env>-spoke-vnet; workload resource groups should use the
# keyed <workload>-<region>-<env>-<purpose>-rg output where the root splits
# purpose-specific groups. The legacy one-RG output is retained below for the
# current internal-apps decision.
# tfvars overrides any name via merge() in main.tf.
# =============================================================================

module "naming" {
  source = "../../../../modules/terraform-azurerm-compeer-naming"

  region      = var.location
  environment = var.environment
  scope       = "workload"
  domain      = var.workload_domain
  appcode     = var.workload_appcode

  nsg_keys              = keys(try(var.workload_spoke.network_security_groups, {}))
  route_table_keys      = keys(try(var.workload_spoke.route_tables, {}))
  private_endpoint_keys = keys(try(var.workload_spoke.private_endpoints, {}))
  storage_account_keys  = keys(try(var.workload_spoke.workload_storage_accounts, {}))
  storage_uniqueness    = var.subscription_id
}

locals {
  std_names = {
    resource_group = module.naming.workload_resource_group # legacy one-RG shape
    spoke_vnet     = module.naming.workload_vnet           # <workload>-<region>-<env>-spoke-vnet
    # null unless workload_appcode is set - workload_key_vault.name in
    # tfvars still wins either way via the coalesce() in main.tf.
    workload_key_vault = module.naming.key_vault # <appcode>-<region>-<env>-vault
  }

  std_maps = {
    network_security_groups = {
      for k, val in try(var.workload_spoke.network_security_groups, {}) : k => merge({ name = module.naming.nsg_names[k] }, val)
    }
    route_tables = {
      for k, val in try(var.workload_spoke.route_tables, {}) : k => merge({ name = module.naming.route_table_names[k] }, val)
    }
    private_endpoints = {
      for k, val in try(var.workload_spoke.private_endpoints, {}) : k => merge({ name = module.naming.private_endpoint_names[k] }, val)
    }
    workload_storage_accounts = {
      for k, val in try(var.workload_spoke.workload_storage_accounts, {}) : k => merge({ name = module.naming.storage_account_names[k] }, val)
    }
  }
}
