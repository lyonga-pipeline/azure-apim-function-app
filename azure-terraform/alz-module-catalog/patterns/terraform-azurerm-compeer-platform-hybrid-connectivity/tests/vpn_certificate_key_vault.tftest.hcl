mock_provider "azurerm" {}

# Exercises the optional VPN certificate Key Vault + managed identity + RBAC
# (network engineer request). Had zero test coverage before this file.

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
    error_message = "VPN certificate key vault should be inert by default"
  }
}

run "enabled_creates_vault_identity_and_rbac" {
  # plan, not apply: azurerm_role_assignment's `scope` argument format-checks
  # its value even against the mock provider, and at apply time that value
  # would be the Key Vault's mocked (non-Azure-ID-shaped) id. At plan time
  # the scope is still unknown, so the check doesn't run - but the resource
  # counts (from static for_each key sets) are still knowable.
  command = plan
  variables {
    vpn_certificate_key_vault = {
      enabled = true
      name    = "kv-vpn-cert-test"
    }
  }
  assert {
    condition     = length(module.vpn_certificate_key_vault) == 1
    error_message = "expected the vault to be created"
  }
  assert {
    condition     = length(module.vpn_certificate_identity) == 1
    error_message = "expected the managed identity to be created"
  }
  assert {
    condition     = length(module.vpn_certificate_key_vault_rbac.assignments) == 3
    error_message = "expected exactly 3 role assignments (Administrator, Certificates User, Secrets User)"
  }
}

run "public_mode_with_allow_list_passes" {
  # network.mode = "selected" with an allow-list wires straight through to
  # the underlying keyvault module, which enforces its own compensating-
  # control precondition (public_network_access_enabled = true requires
  # network_acls Deny + a non-empty allow-list) - that module's own test
  # suite covers the negative case; this just confirms the toggle passes
  # through correctly on the happy path.
  command = plan
  variables {
    vpn_certificate_key_vault = {
      enabled = true
      name    = "kv-vpn-cert-test"
      network = { mode = "selected", allowed_ip_ranges = ["203.0.113.4/32"] }
    }
  }
  assert {
    condition     = local.vckv_public == true
    error_message = "network.mode = selected should flip vckv_public"
  }
}
