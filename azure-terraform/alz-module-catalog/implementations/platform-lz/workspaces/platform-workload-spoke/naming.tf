# =============================================================================
# Naming standard (design-doc Appendix F). A workload spoke names itself from
# its domain token: RG = <domain>-<env>-rg, VNet = <domain>-<region>-<env>-vnet.
# tfvars overrides any name via merge() in main.tf.
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
    spoke_vnet     = module.naming.workload_vnet           # <domain>-<region>-<env>-vnet
  }
}
