locals {
  enabled = try(var.workload_identity.enabled, false)
}

module "workload_identity" {
  source = "../../../../patterns/terraform-azurerm-compeer-workload-identity"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
    azuread = azuread
  }

  workload_identities   = try(var.workload_identity.workload_identities, {})
  operational_contracts = try(var.workload_identity.operational_contracts, {})
}
