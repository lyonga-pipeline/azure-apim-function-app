# =============================================================================
# Naming standard (design-doc Appendix F) for the Palo Alto hub. The firewalls
# live in the connectivity/hub resource group. tfvars overrides any name via
# the merge() calls in main.tf - keep the workspace disabled until the Palo hub
# build is approved (firewall VM / NIC names are ForceNew).
# =============================================================================

module "naming" {
  source = "../../../../modules/terraform-azurerm-compeer-naming"

  region      = var.location
  environment = var.environment
}

module "naming_vm" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.palo_alto.virtual_machines, {})
  region      = var.location
  environment = var.environment
  instance    = try(tonumber(regex("[0-9]+$", each.key)), 1)
}

module "naming_nic" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.palo_alto.network_interfaces, {})
  region      = var.location
  environment = var.environment
  resource    = each.key
}

module "naming_lb" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.palo_alto.load_balancers, {})
  region      = var.location
  environment = var.environment
  purpose     = each.key
}

module "naming_pip" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.palo_alto.public_ips, {})
  region      = var.location
  environment = var.environment
  resource    = each.key
}

locals {
  std_pip = {
    for k, v in try(var.palo_alto.public_ips, {}) : k => merge({ name = module.naming_pip[k].public_ip }, v)
  }
}
