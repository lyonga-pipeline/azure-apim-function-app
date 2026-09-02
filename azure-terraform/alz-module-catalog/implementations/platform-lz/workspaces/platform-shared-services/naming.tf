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

locals {
  std_names = {
    resource_group = module.naming.workload_resource_group # <domain>-<env>-rg
    shared_vnet    = module.naming.shared_vnet             # platform-<region>-<env>-shared-vnet
  }
}
