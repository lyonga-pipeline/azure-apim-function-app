# PHASE2 NEW: isolated state/identity; promote to an approved pinned registry release before deployment.
module "phase2" {
  source              = "../../../../patterns/terraform-azurerm-compeer-platform-services"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  galleries           = var.galleries
  patch_schedules     = var.patch_schedules
}
