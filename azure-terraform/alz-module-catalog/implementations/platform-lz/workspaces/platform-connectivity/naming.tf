# =============================================================================
# Naming standard (design-doc Appendix F) wired for the connectivity workspace.
# `terraform-azurerm-compeer-naming` is the single versioned implementation;
# this root only selects the top-level names it needs. tfvars still overrides
# any name (see the merge() calls in main.tf) - useful for grandfathered
# "Existing" rows. Nested names (bastion.name, ddos.name, per-key NSG/RT/PIP
# maps) are still taken from tfvars - see HARDENING_STATUS.md Phase 6.
# =============================================================================

module "naming" {
  source = "../../../../modules/terraform-azurerm-compeer-naming"

  region      = var.location
  environment = var.environment
  purpose     = "connectivity" # per-capability RG token
}

locals {
  std_names = {
    resource_group = module.naming.resource_group # platform-<region>-<env>-connectivity-rg
    hub_vnet       = module.naming.hub_vnet       # platform-<region>-<env>-hub-vnet
  }
}
