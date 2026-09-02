# =============================================================================
# Naming standard (design-doc Appendix F) wired for the connectivity workspace.
# `terraform-azurerm-compeer-naming` is the single versioned implementation;
# this root only selects the names it needs. tfvars still overrides any name
# (see the merge() calls below / in main.tf) - useful for grandfathered
# "Existing" rows.
#
# Reserved subnet names (GatewaySubnet, AzureBastionSubnet, RouteServerSubnet,
# ...) are an Azure hard constraint and stay operator-controlled via the subnet
# map key - not named here.
# =============================================================================

module "naming" {
  source = "../../../../modules/terraform-azurerm-compeer-naming"

  region      = var.location
  environment = var.environment
  purpose     = "connectivity" # per-capability RG token
}

# Per-key naming: one module instance per map entry, the key carries the
# purpose / destination / resource token from Appendix F.
module "naming_nsg" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.connectivity.network_security_groups, {})
  region      = var.location
  environment = var.environment
  purpose     = each.key
}

module "naming_rt" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.connectivity.route_tables, {})
  region      = var.location
  environment = var.environment
  destination = each.key
}

module "naming_pip" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.connectivity.public_ips, {})
  region      = var.location
  environment = var.environment
  resource    = each.key
}

module "naming_rs_pip" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.connectivity.route_server_public_ips, {})
  region      = var.location
  environment = var.environment
  resource    = each.key
}

locals {
  std_names = {
    resource_group = module.naming.resource_group # platform-<region>-<env>-connectivity-rg
    hub_vnet       = module.naming.hub_vnet       # platform-<region>-<env>-hub-vnet
  }

  std_maps = {
    network_security_groups = {
      for k, v in try(var.connectivity.network_security_groups, {}) : k => merge({ name = module.naming_nsg[k].nsg }, v)
    }
    route_tables = {
      for k, v in try(var.connectivity.route_tables, {}) : k => merge({ name = module.naming_rt[k].route_table }, v)
    }
    public_ips = {
      for k, v in try(var.connectivity.public_ips, {}) : k => merge({ name = module.naming_pip[k].public_ip }, v)
    }
    route_server_public_ips = {
      for k, v in try(var.connectivity.route_server_public_ips, {}) : k => merge({ name = module.naming_rs_pip[k].public_ip }, v)
    }
  }
}
