# =============================================================================
# Naming standard (design-doc Appendix F). Shared Services is a workload-tier
# domain, so its RG/VNet use the <domain>-<env> form. tfvars overrides any name
# via merge() in main.tf.
# =============================================================================

module "naming" {
  source = "../../../../modules/terraform-azurerm-compeer-naming"

  region      = var.location
  environment = var.environment
  domain      = var.workload_domain
}


module "naming_nsg" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.shared_services.network_security_groups, {})
  region      = var.location
  environment = var.environment
  purpose     = each.key
}

module "naming_rt" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.shared_services.route_tables, {})
  region      = var.location
  environment = var.environment
  destination = each.key
}

module "naming_pe" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.shared_services.private_endpoints, {})
  region      = var.location
  environment = var.environment
  resource    = each.key
}

locals {
  std_names = {
    resource_group = module.naming.workload_resource_group # <domain>-<env>-rg
    shared_vnet    = module.naming.shared_vnet             # platform-<region>-<env>-shared-vnet
  }

  std_maps = {
    network_security_groups = {
      for k, val in try(var.shared_services.network_security_groups, {}) : k => merge({ name = module.naming_nsg[k].nsg }, val)
    }
    route_tables = {
      for k, val in try(var.shared_services.route_tables, {}) : k => merge({ name = module.naming_rt[k].route_table }, val)
    }
    private_endpoints = {
      for k, val in try(var.shared_services.private_endpoints, {}) : k => merge({ name = module.naming_pe[k].private_endpoint }, val)
    }
  }
}
