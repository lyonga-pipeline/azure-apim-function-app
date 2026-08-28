locals {
  tags = merge({
    Environment = var.environment
    ManagedBy   = "Terraform"
    IaCSource   = "AVM+CompeerHCP"
    LandingZone = "CentralUS"
  }, var.tags)
  lock = var.enable_resource_locks ? { kind = "CanNotDelete", name = "terraform-protection" } : null
  rg_names = {
    management = "${var.prefix}-${var.environment}-cus-management-rg"
    security   = "${var.prefix}-${var.environment}-cus-security-rg"
  }
}
