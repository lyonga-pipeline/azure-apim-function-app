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
  purpose     = "identity"
}

locals {
  std_names = {
    resource_group = module.naming.resource_group # platform-<region>-<env>-identity-rg
  }
}
