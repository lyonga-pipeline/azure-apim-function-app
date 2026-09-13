mock_provider "azurerm" {}

# Had zero test coverage before this file. shared_services is a thin wrapper
# around workload-spoke (module "shared_services" { source =
# "../terraform-azurerm-compeer-workload-spoke" ... }) - this confirms the
# wrapper itself plans cleanly and that the network_acls fix in workload-spoke
# (see its own tests) is inherited here too, since shared-services is the
# platform's own consumer of that exact code path.

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "11111111-1111-1111-1111-111111111111"
  location        = "centralus"
  environment     = "prod"
  resource_group  = { name = "rg-shared-services-prod" }
  spoke_vnet = {
    name          = "vnet-shared-services-prod"
    address_space = ["10.20.0.0/24"]
    subnets = {
      app = { address_prefixes = ["10.20.0.0/26"] }
    }
  }
}

run "empty_config_is_a_noop" {
  command = plan
  assert {
    condition     = output.platform_key_vault_id == null
    error_message = "no platform key vault by default"
  }
}

run "platform_key_vault_without_network_acls_does_not_crash_plan" {
  command = apply
  variables {
    platform_key_vault = {
      enabled = true
      name    = "kv-shared-services-prod"
    }
  }
  assert {
    condition     = output.platform_key_vault_id != null
    error_message = "expected the shared-services key vault to be created without needing an explicit network_acls"
  }
}
