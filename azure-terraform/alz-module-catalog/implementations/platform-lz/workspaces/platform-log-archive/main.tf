# PHASE2 NEW: isolated state/identity; promote to an approved pinned registry release before deployment.
module "phase2" {
  source              = "../../../../patterns/terraform-azurerm-compeer-log-archive"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  archive             = var.archive
}
