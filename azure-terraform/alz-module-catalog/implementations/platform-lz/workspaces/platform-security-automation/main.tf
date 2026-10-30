# PHASE2 NEW: isolated state/identity; promote to an approved pinned registry release before deployment.
module "phase2" {
  source           = "../../../../patterns/terraform-azurerm-compeer-security-automation"
  tags             = var.tags
  secret_rotations = var.secret_rotations
}
