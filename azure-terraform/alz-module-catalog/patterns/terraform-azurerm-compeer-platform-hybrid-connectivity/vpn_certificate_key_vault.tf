# =============================================================================
# Optional Key Vault + managed identity for VPN gateway certificate
# management (network engineer request). Mirrors palo-alto-hub's
# bootstrap_key_vault pattern: a private-by-default vault, a user-assigned
# identity (there's no VM in this pattern to own a system-assigned one), and
# RBAC granting that identity access to certs/secrets.
#
# Note: azurerm's virtual_network_gateway / vpn_connection resources have no
# native "read this certificate from Key Vault" argument for a site-to-site
# gateway - this wiring gives whatever automation manages the gateway's
# certificates (rotation tooling, a pipeline step) a vault to read from and
# an identity to read it with, rather than claiming a direct provider
# integration that doesn't exist for this resource type.
#
# Default posture is PRIVATE (public_network_access_enabled = false + a
# private endpoint). Set network.mode = "selected" only with an approved
# exception - the keyvault module then requires a Deny + IP/subnet allow-list.
# =============================================================================

locals {
  vckv            = var.vpn_certificate_key_vault
  vckv_enabled    = coalesce(try(local.vckv.enabled, null), false)
  vckv_mode       = try(local.vckv.network.mode, "private") # private | selected
  vckv_public     = local.vckv_mode == "selected"
  vckv_pe_enabled = local.vckv_enabled && try(local.vckv.private_endpoint, null) != null
}

module "vpn_certificate_identity" {
  source = "../../modules/terraform-azurerm-compeer-user-assigned-identity"
  count  = local.vckv_enabled ? 1 : 0

  name                = coalesce(try(var.vpn_certificate_identity.name, null), "id-vpn-cert-${var.environment}")
  resource_group_name = module.resource_group.name
  location            = var.location
  tags                = module.tags.tags
}

module "vpn_certificate_key_vault" {
  source = "../../modules/terraform-azurerm-compeer-keyvault"
  count  = local.vckv_enabled ? 1 : 0

  name                          = coalesce(try(local.vckv.name, null), "kv-vpn-cert-${var.environment}")
  resource_group_name           = module.resource_group.name
  location                      = var.location
  tenant_id                     = var.tenant_id
  sku_name                      = try(local.vckv.sku_name, "premium")
  purge_protection_enabled      = try(local.vckv.purge_protection_enabled, true)
  soft_delete_retention_days    = try(local.vckv.soft_delete_retention_days, 90)
  rbac_authorization_enabled    = true
  public_network_access_enabled = local.vckv_public
  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = local.vckv_public ? try(local.vckv.network.allowed_ip_ranges, []) : []
    virtual_network_subnet_ids = local.vckv_public ? try(local.vckv.network.allowed_subnet_ids, []) : []
  }
  tags = module.tags.tags
}

# The 3 roles the network engineer asked for by name. Key Vault Administrator
# already implies certs/secrets read access on its own - the narrower roles
# are granted alongside it anyway per that explicit request, so the intended
# day-to-day access path (Certificates/Secrets User) is visible in its own
# right rather than only implied by the broader Administrator grant.
module "vpn_certificate_key_vault_rbac" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.vckv_enabled ? {
    administrator = {
      scope                = module.vpn_certificate_key_vault[0].id
      principal_id         = module.vpn_certificate_identity[0].principal_id
      role_definition_name = "Key Vault Administrator"
      principal_type       = "ServicePrincipal"
      description          = "VPN certificate management identity - vault administration"
    }
    certificates = {
      scope                = module.vpn_certificate_key_vault[0].id
      principal_id         = module.vpn_certificate_identity[0].principal_id
      role_definition_name = "Key Vault Certificates User"
      principal_type       = "ServicePrincipal"
      description          = "VPN certificate management identity - read certificates"
    }
    secrets = {
      scope                = module.vpn_certificate_key_vault[0].id
      principal_id         = module.vpn_certificate_identity[0].principal_id
      role_definition_name = "Key Vault Secrets User"
      principal_type       = "ServicePrincipal"
      description          = "VPN certificate management identity - read secrets"
    }
  } : {}
}

module "vpn_certificate_key_vault_private_endpoint" {
  source = "../../modules/terraform-azurerm-compeer-private-endpoint"
  count  = local.vckv_pe_enabled ? 1 : 0

  name                = local.vckv.private_endpoint.name
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = local.vckv.private_endpoint.subnet_id
  private_service_connections = [{
    name                           = "${local.vckv.private_endpoint.name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = module.vpn_certificate_key_vault[0].id
    subresource_names              = ["vault"]
  }]
  private_dns_zone_group = length(try(local.vckv.private_endpoint.private_dns_zone_ids, [])) == 0 ? [] : [{
    name                 = "default"
    private_dns_zone_ids = local.vckv.private_endpoint.private_dns_zone_ids
  }]
  tags = module.tags.tags
}
