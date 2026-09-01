# =============================================================================
# Optional bootstrap Key Vault for the firewalls (cert authentication,
# Panorama/API secrets). Composed here so the network posture and the
# firewall-MI RBAC are owned in one place.
#
# Default posture is PRIVATE (public_network_access_enabled = false + a private
# endpoint). Set network.mode = "selected" only with an approved exception -
# the keyvault module then requires a Deny + IP/subnet allow-list.
# =============================================================================

locals {
  bkv                  = var.bootstrap_key_vault
  bkv_enabled          = var.enabled && local.bkv != null
  bkv_mode             = try(local.bkv.network.mode, "private") # private | selected
  bkv_public           = local.bkv_mode == "selected"
  bkv_pe_enabled       = local.bkv_enabled && try(local.bkv.private_endpoint, null) != null
  bkv_fw_principal_ids = { for k, vm in azurerm_linux_virtual_machine.this : k => try(vm.identity[0].principal_id, null) }
}

module "bootstrap_key_vault" {
  source = "../../modules/terraform-azurerm-compeer-keyvault"
  count  = local.bkv_enabled ? 1 : 0

  name                          = local.bkv.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  tenant_id                     = local.bkv.tenant_id
  sku_name                      = try(local.bkv.sku_name, "premium")
  purge_protection_enabled      = try(local.bkv.purge_protection_enabled, true)
  soft_delete_retention_days    = try(local.bkv.soft_delete_retention_days, 90)
  rbac_authorization_enabled    = true
  public_network_access_enabled = local.bkv_public
  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = local.bkv_public ? try(local.bkv.network.allowed_ip_ranges, []) : []
    virtual_network_subnet_ids = local.bkv_public ? try(local.bkv.network.allowed_subnet_ids, []) : []
  }
  tags = var.tags
}

# Firewall managed identities get read access to the vault's certs + secrets.
module "bootstrap_key_vault_rbac" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.bkv_enabled ? merge([
    for vm_key, pid in local.bkv_fw_principal_ids : {
      "${vm_key}-kv-certs" = {
        scope                = module.bootstrap_key_vault[0].id
        principal_id         = pid
        role_definition_name = "Key Vault Certificates User"
        principal_type       = "ServicePrincipal"
        description          = "Palo Alto ${vm_key} - bootstrap cert authentication"
      }
      "${vm_key}-kv-secrets" = {
        scope                = module.bootstrap_key_vault[0].id
        principal_id         = pid
        role_definition_name = "Key Vault Secrets User"
        principal_type       = "ServicePrincipal"
        description          = "Palo Alto ${vm_key} - bootstrap secret read"
      }
    }
  ]...) : {}
}

module "bootstrap_key_vault_private_endpoint" {
  source = "../../modules/terraform-azurerm-compeer-private-endpoint"
  count  = local.bkv_pe_enabled ? 1 : 0

  name                = local.bkv.private_endpoint.name
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = local.bkv.private_endpoint.subnet_id
  private_service_connections = [{
    name                           = "${local.bkv.private_endpoint.name}-psc"
    is_manual_connection           = false
    private_connection_resource_id = module.bootstrap_key_vault[0].id
    subresource_names              = ["vault"]
  }]
  private_dns_zone_group = length(try(local.bkv.private_endpoint.private_dns_zone_ids, [])) == 0 ? [] : [{
    name                 = "default"
    private_dns_zone_ids = local.bkv.private_endpoint.private_dns_zone_ids
  }]
  tags = var.tags
}
