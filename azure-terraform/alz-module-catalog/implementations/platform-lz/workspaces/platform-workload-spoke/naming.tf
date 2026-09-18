# =============================================================================
# Naming standard (design-doc Appendix F). A workload spoke names itself from
# its domain token: RG = <domain>-<env>-rg, VNet = <domain>-<region>-<env>-vnet.
# tfvars overrides any name via merge() in main.tf.
# =============================================================================

module "naming" {
  source = "../../../../modules/terraform-azurerm-compeer-naming"

  region      = var.location
  environment = var.environment
  domain      = var.workload_domain
  appcode     = var.workload_appcode

  # Storage accounts go through the keyed front door, not a per-instance
  # naming_xxx call like NSGs/route tables/PEs below - storage account names
  # are globally unique across all of Azure, not just this subscription, so
  # they need the storage_uniqueness suffix mechanism the keyed
  # storage_account_names output has and the legacy singular one doesn't.
  storage_account_keys = keys(try(var.workload_spoke.workload_storage_accounts, {}))
  storage_uniqueness   = var.subscription_id
}


module "naming_nsg" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.workload_spoke.network_security_groups, {})
  region      = var.location
  environment = var.environment
  purpose     = each.key
}

module "naming_rt" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.workload_spoke.route_tables, {})
  region      = var.location
  environment = var.environment
  destination = each.key
}

module "naming_pe" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.workload_spoke.private_endpoints, {})
  region      = var.location
  environment = var.environment
  resource    = each.key
}

locals {
  std_names = {
    resource_group = module.naming.workload_resource_group # <domain>-<env>-rg
    spoke_vnet     = module.naming.workload_vnet           # <domain>-<region>-<env>-vnet
    # null unless workload_appcode is set - workload_key_vault.name in
    # tfvars still wins either way via the coalesce() in main.tf.
    workload_key_vault = module.naming.key_vault # <appcode>-<region>-<env>-vault
  }

  std_maps = {
    network_security_groups = {
      for k, val in try(var.workload_spoke.network_security_groups, {}) : k => merge({ name = module.naming_nsg[k].nsg }, val)
    }
    route_tables = {
      for k, val in try(var.workload_spoke.route_tables, {}) : k => merge({ name = module.naming_rt[k].route_table }, val)
    }
    private_endpoints = {
      for k, val in try(var.workload_spoke.private_endpoints, {}) : k => merge({ name = module.naming_pe[k].private_endpoint }, val)
    }
    workload_storage_accounts = {
      for k, val in try(var.workload_spoke.workload_storage_accounts, {}) : k => merge({ name = module.naming.storage_account_names[k] }, val)
    }
  }
}
