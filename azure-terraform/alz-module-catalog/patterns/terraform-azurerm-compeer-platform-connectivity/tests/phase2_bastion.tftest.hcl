# PHASE2 EXISTING: SEC-12 centrally owned, not one Bastion per application spoke.
mock_provider "azurerm" {}
variables {
  subscription_id = "11111111-1111-1111-1111-111111111111"
  location        = "centralus"
  environment     = "prod"
  resource_group  = { name = "platform-cus-prod-network-rg" }
  hub_vnet = {
    name          = "platform-cus-prod-hub-vnet"
    address_space = ["10.102.0.0/21"]
    subnets       = { AzureBastionSubnet = { address_prefixes = ["10.102.2.0/26"] } }
  }
  privatelink_zone_catalogue = []
}
run "central_bastion_reuses_public_ip_and_routes_audit" {
  command = plan
  variables {
    bastion = {
      enabled      = true
      public_ip_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/platform-cus-prod-network-rg/providers/Microsoft.Network/publicIPAddresses/bastion-pip"
      diagnostic_settings = { central = {
        log_analytics_workspace_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/central-law"
      } }
    }
  }
  assert {
    condition     = length(module.bastion) == 1 && length(module.bastion_public_ip) == 0 && length(module.bastion_diagnostics) == 1
    error_message = "Central privileged access must support an existing PIP and diagnostic routing without creating a second PIP."
  }
}
run "bastion_stays_disabled_until_approved" {
  command = plan
  assert {
    condition     = length(module.bastion) + length(module.bastion_public_ip) + length(module.bastion_diagnostics) == 0
    error_message = "Phase 2 coverage must not enable new public ingress by default."
  }
}
