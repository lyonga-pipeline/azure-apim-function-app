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
  purpose     = "directory-services"
}

# DEVIATION (tracks A2): the adapted DC VM pattern platform-<region>-<env>-dc-0<n>
# differs from the legacy AZR-SRV-ADDS-01 convention. It is wired only as the
# default - tfvars `name` / `computer_name` still win - pending AD-team sign-off.
# `computer_name` (NetBIOS, <=15 chars) is NOT defaulted here; keep it in tfvars.
module "naming_dc" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.directory_services.domain_controllers, {})
  region      = var.location
  environment = var.environment
  resource    = each.key
  instance    = try(tonumber(regex("[0-9]+$", each.key)), 1)
}

locals {
  std_names = {
    resource_group = module.naming.resource_group # platform-<region>-<env>-directory-services-rg
  }
}
