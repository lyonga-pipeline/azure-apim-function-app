mock_provider "azurerm" {}

# Exercises the VPN certificate managed identity + RBAC (network engineer
# request). As of the resource-placement sheet's security-mg placement,
# this pattern no longer creates its own Key Vault - it only grants
# vpn_certificate_identity access to an externally-owned vault ID
# (platform-cus-prod-vault, owned by platform-identity-security).

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "11111111-1111-1111-1111-111111111111"
  location        = "centralus"
  environment     = "prod"
  resource_group  = { name = "rg-hybrid" }
}

run "off_by_default_is_a_noop" {
  command = plan
  assert {
    condition     = local.vckv_enabled == false
    error_message = "VPN certificate key vault access should be inert by default"
  }
}

run "enabled_without_key_vault_id_is_a_graceful_noop" {
  # platform-identity-security not yet deployed (or not yet publishing
  # key_vault_id) must not be a hard error - same idiom as every other
  # optional cross-workspace dependency in this catalog (e.g. hub_connection).
  command = plan
  variables {
    vpn_certificate_key_vault = {
      enabled = true
    }
  }
  assert {
    condition     = local.vckv_enabled == false
    error_message = "enabled = true without a resolved key_vault_id should stay inert, not error"
  }
  assert {
    condition     = length(module.vpn_certificate_identity) == 0
    error_message = "no identity should be created until key_vault_id is available"
  }
}

run "enabled_with_key_vault_id_creates_identity_and_rbac" {
  command = plan
  variables {
    vpn_certificate_key_vault = {
      enabled      = true
      key_vault_id = "/subscriptions/x/resourceGroups/rg-security/providers/Microsoft.KeyVault/vaults/platform-cus-prod-vault"
    }
  }
  assert {
    condition     = length(module.vpn_certificate_identity) == 1
    error_message = "expected the managed identity to be created"
  }
  assert {
    condition     = length(module.vpn_certificate_key_vault_rbac.assignments) == 2
    error_message = "expected exactly 2 role assignments (Certificates User, Secrets User) - no Key Vault Administrator on a shared vault"
  }
  assert {
    condition     = alltrue([for a in module.vpn_certificate_key_vault_rbac.assignments : a.role_definition_name != "Key Vault Administrator"])
    error_message = "Key Vault Administrator must not be granted on the shared platform vault"
  }
}
