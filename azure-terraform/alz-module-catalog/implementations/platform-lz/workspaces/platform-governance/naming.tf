# =============================================================================
# Naming standard (design-doc Appendix F) - management group display names.
# The MG key carries the node token (and the env suffix for domain+env nodes);
# `mg` = <token>-mg. The LZ root is the one fixed exception.
# tfvars display_name still overrides via merge() in main.tf.
# =============================================================================

module "naming" {
  source = "../../../../modules/terraform-azurerm-compeer-naming"

  region      = var.location
  environment = var.environment
}

module "naming_mg" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.governance.management_groups, {})
  region      = var.location
  environment = var.environment
  domain      = replace(each.key, "_", "-")
}

locals {
  std_management_groups = {
    for k, v in try(var.governance.management_groups, {}) : k => merge(
      { display_name = k == "enterprise" ? module.naming.mg_enterprise : module.naming_mg[k].mg },
      v
    )
  }
}
