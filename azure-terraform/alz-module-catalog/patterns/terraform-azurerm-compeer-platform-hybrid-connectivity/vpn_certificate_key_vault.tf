# =============================================================================
# Managed identity for VPN gateway certificate management (network engineer
# request), granted access to the shared platform Key Vault
# (platform-cus-prod-vault, security-mg / platform-identity-security) rather
# than a dedicated vault of this pattern's own - see the resource-placement
# sheet's security-mg / platform-cus-prod-keyvault-rg row for VPN
# certificates. This pattern does not create or own that vault; it only
# creates the identity and grants it narrow, vault-scoped roles on the
# externally-owned vault ID the caller supplies.
#
# Note: azurerm's virtual_network_gateway / vpn_connection resources have no
# native "read this certificate from Key Vault" argument for a site-to-site
# gateway - this wiring gives whatever automation manages the gateway's
# certificates (rotation tooling, a pipeline step) an identity to read with,
# rather than claiming a direct provider integration that doesn't exist for
# this resource type.
#
# Only Certificates User + Secrets User are granted - NOT Key Vault
# Administrator. The vault is now shared with other platform secrets, so a
# narrow-purpose VPN identity gets read access to what it needs, not vault
# administration; the previous dedicated-vault version of this file granted
# Administrator too, which was reasonable for a vault this identity solely
# owned but is too broad for a shared one.
# =============================================================================

locals {
  vckv = var.vpn_certificate_key_vault
  # Both enabled = true AND a resolved key_vault_id are required - if
  # platform-identity-security hasn't published a vault ID yet (not yet
  # deployed), this stays false rather than erroring, exactly like this
  # catalog's other optional cross-workspace dependencies (e.g.
  # hub_connection): the identity/RBAC simply appear on a later apply once
  # that workspace exists.
  vckv_enabled = coalesce(try(local.vckv.enabled, null), false) && try(local.vckv.key_vault_id, null) != null
}

module "vpn_certificate_identity" {
  source = "../../modules/terraform-azurerm-compeer-user-assigned-identity"
  count  = local.vckv_enabled ? 1 : 0

  name                = coalesce(try(var.vpn_certificate_identity.name, null), "id-vpn-cert-${var.environment}")
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = module.tags.tags
}

module "vpn_certificate_key_vault_rbac" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.vckv_enabled ? {
    certificates = {
      scope                = local.vckv.key_vault_id
      principal_id         = module.vpn_certificate_identity[0].principal_id
      role_definition_name = "Key Vault Certificates User"
      principal_type       = "ServicePrincipal"
      description          = "VPN certificate management identity - read certificates from the shared platform Key Vault"
    }
    secrets = {
      scope                = local.vckv.key_vault_id
      principal_id         = module.vpn_certificate_identity[0].principal_id
      role_definition_name = "Key Vault Secrets User"
      principal_type       = "ServicePrincipal"
      description          = "VPN certificate management identity - read secrets from the shared platform Key Vault"
    }
  } : {}
}
