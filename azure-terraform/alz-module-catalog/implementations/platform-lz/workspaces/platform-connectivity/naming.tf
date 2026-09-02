# =============================================================================
# Reference wiring for the naming standard (Appendix F). The module is the
# single versioned implementation; this root only picks the names it needs and
# passes them into the connectivity pattern. tfvars still wins where a name is
# set explicitly (see the merge() calls in main.tf) - useful for the "Existing"
# rows that predate the new standard.
# =============================================================================

module "naming" {
  source = "../../../../modules/terraform-azurerm-compeer-naming"

  region      = var.location
  environment = var.environment
}

locals {
  std_names = {
    resource_group = module.naming.platform_resource_group # platform-<region>-<env>-rg
    hub_vnet       = module.naming.hub_vnet                # platform-<region>-<env>-hub-vnet
  }
}
