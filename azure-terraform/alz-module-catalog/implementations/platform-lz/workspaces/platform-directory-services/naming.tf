# =============================================================================
# Naming standard (design-doc Appendix F). `terraform-azurerm-compeer-naming`
# is the single versioned implementation; this root selects the top-level names
# it needs. tfvars still overrides any name via the merge() in main.tf.
# Nested / per-key names stay in tfvars for now - see HARDENING_STATUS.md Phase 6.
# =============================================================================

module "naming" {
  source = "../../../../modules/terraform-azurerm-compeer-naming"

  region      = var.location
  environment = var.environment
  component   = "directory-services"

  network_interface_keys       = keys(try(var.directory_services.domain_controllers, {}))
  recovery_services_vault_keys = keys(try(var.directory_services.recovery_services_vaults, {}))
  nsg_keys                     = keys(try(var.directory_services.network_security_groups, {}))
  route_table_keys             = keys(try(var.directory_services.route_tables, {}))
}

# DEVIATION (tracks A2): the adapted DC VM pattern platform-<region>-<env>-dc-0<n>
# differs from the legacy AZR-SRV-ADDS-01 convention. It is wired only as the
# default - tfvars `name` / `computer_name` still win - pending AD-team sign-off.
# `computer_name` (NetBIOS, <=15 chars) is NOT defaulted here; keep it in tfvars.
#
# Two independent domain families as of the 23 Sep 2026 placement decision:
# keys starting with "ext" (extdc01, extdc02, ...) are the compeer.ext forest
# and use domain_controller_extdc_vm (platform-<region>-<env>-extdc-0<n>);
# everything else (dc01, dc02, ...) is the primary/"compeer forest" domain and
# uses domain_controller_vm (platform-<region>-<env>-dc-0<n>). Each family
# numbers its own instances independently (dc01/dc02 and extdc01/extdc02 both
# start at 01) - `instance` is parsed from the trailing digits of the key.
module "naming_dc" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.directory_services.domain_controllers, {})
  region      = var.location
  environment = var.environment
  resource    = each.key
  instance    = try(tonumber(regex("[0-9]+$", each.key)), 1)
}

locals {
  domain_controller_names = {
    for key, module_instance in module.naming_dc : key => (
      startswith(key, "ext") ? module_instance.domain_controller_extdc_vm : module_instance.domain_controller_vm
    )
  }

  # Windows computer_name (NetBIOS, <=15 chars) - distinct from the Azure VM
  # resource name above. AZR-<region>-<role>-0<n>, guaranteed <=15 chars in
  # every approved region by the naming module's own precondition. tfvars
  # can still override per-key via `computer_name` if AD/network team
  # guidance (the Teams "New Landing Zone - Cloud Enablement" thread)
  # eventually lands on a different convention.
  domain_controller_computer_names = {
    for key, module_instance in module.naming_dc : key => (
      startswith(key, "ext") ? module_instance.domain_controller_extdc_computer_name : module_instance.domain_controller_computer_name
    )
  }

  std_names = {
    resource_group          = module.naming.resource_group
    identity_vnet           = module.naming.identity_vnet
    recovery_services_vault = module.naming.recovery_services_vault_names
    nsg                     = module.naming.nsg_names
    route_table             = module.naming.route_table_names
  }
}
