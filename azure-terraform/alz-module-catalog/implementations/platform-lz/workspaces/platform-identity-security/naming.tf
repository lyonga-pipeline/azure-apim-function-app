# =============================================================================
# Naming standard (design-doc Appendix F). The naming module is the single
# versioned implementation; this root feeds the names into the identity pattern
# (merge() in main.tf). A `name` in terraform.tfvars still wins - grandfather
# only.
# =============================================================================

module "naming" {
  source = "../../../../modules/terraform-azurerm-compeer-naming"

  region      = var.location
  environment = var.environment
  purpose     = "identity"
  appcode     = "platform" # key vault: <appcode>-<region>-<env>-vault
}

# user-assigned identities: <key>-<region>-<env>-id
module "naming_uai" {
  source      = "../../../../modules/terraform-azurerm-compeer-naming"
  for_each    = try(var.identity.platform_identities, {})
  region      = var.location
  environment = var.environment
  purpose     = each.key
}

locals {
  std_names = {
    resource_group = module.naming.resource_group # platform-<region>-<env>-identity-rg
    key_vault      = module.naming.key_vault      # platform-<region>-<env>-vault
  }

  identity_platform_identities = {
    for k, v in try(var.identity.platform_identities, {}) : k => merge({ name = module.naming_uai[k].user_assigned_identity }, v)
  }
}
