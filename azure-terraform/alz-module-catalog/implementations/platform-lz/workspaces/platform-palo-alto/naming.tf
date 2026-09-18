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
  component   = "palo-alto"

  network_interface_keys = keys(try(var.palo_alto.network_interfaces, {}))
  load_balancer_keys     = keys(try(var.palo_alto.load_balancers, {}))
  public_ip_keys         = keys(try(var.palo_alto.public_ips, {}))
}

module "naming_vm" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.palo_alto.virtual_machines, {})
  region      = var.location
  environment = var.environment
  instance    = try(tonumber(regex("[0-9]+$", each.key)), 1)
}

locals {
  std_pip = {
    for k, v in try(var.palo_alto.public_ips, {}) : k => merge({ name = module.naming.public_ip_names[k] }, v)
  }
}
