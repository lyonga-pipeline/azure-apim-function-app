locals {
  enabled = try(var.authorization.enabled, false)
}

module "authorization" {
  source = "../../../../patterns/terraform-azurerm-compeer-platform-authorization"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
    azuread = azuread
  }

  rbac_groups             = try(var.authorization.rbac_groups, {})
  custom_role_definitions = try(var.authorization.custom_role_definitions, {})
  role_assignments        = try(var.authorization.role_assignments, {})
  operational_contracts   = try(var.authorization.operational_contracts, {})
}
