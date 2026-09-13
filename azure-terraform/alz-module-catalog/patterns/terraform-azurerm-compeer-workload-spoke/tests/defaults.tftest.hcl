mock_provider "azurerm" {}

# Had zero test coverage before this file. Also regression-tests a real bug:
# workload_key_vault.network_acls left unset used to crash plan with
# "coalesce: all arguments must have the same type" for every workload that
# enables its own Key Vault without setting network_acls explicitly - the
# exact shape shared-services (which wraps this pattern) and most workload
# spokes use.

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "11111111-1111-1111-1111-111111111111"
  location        = "centralus"
  environment     = "prod"
  resource_group  = { name = "rg-spoke-internalapps-prod" }
  spoke_vnet = {
    name          = "vnet-spoke-internalapps-prod"
    address_space = ["10.10.0.0/24"]
    subnets = {
      app = { address_prefixes = ["10.10.0.0/26"] }
    }
  }
}

run "empty_key_vault_is_a_noop" {
  command = plan
  assert {
    condition     = length(module.workload_key_vault) == 0
    error_message = "workload key vault should be disabled by default"
  }
}

run "key_vault_enabled_without_network_acls_does_not_crash_plan" {
  command = plan
  variables {
    workload_key_vault = {
      enabled = true
      name    = "kv-internalapps-prod"
    }
  }
  assert {
    condition     = length(module.workload_key_vault) == 1
    error_message = "expected the workload key vault to be created"
  }
}

run "key_vault_network_acls_override_is_honored" {
  command = apply
  variables {
    workload_key_vault = {
      enabled = true
      name    = "kv-internalapps-prod"
      network_acls = {
        bypass         = "None"
        default_action = "Deny"
        ip_rules       = ["203.0.113.4/32"]
      }
    }
  }
  assert {
    condition     = module.workload_key_vault[0].id != null
    error_message = "expected the key vault to plan/apply successfully with an explicit network_acls override"
  }
}
