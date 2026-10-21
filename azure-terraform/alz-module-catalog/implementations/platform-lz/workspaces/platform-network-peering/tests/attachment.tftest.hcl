mock_provider "azurerm" {
  alias = "hub"
  mock_data "azurerm_client_config" {
    defaults = { subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" }
  }
}
mock_provider "azurerm" {
  alias = "spoke"
  mock_data "azurerm_client_config" {
    defaults = { subscription_id = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" }
  }
}
mock_provider "azurerm" {
  alias = "dns"
  mock_data "azurerm_client_config" {
    defaults = { subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" }
  }
}
mock_provider "tfe" {}

variables {
  tenant_id             = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  hub_subscription_id   = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  spoke_subscription_id = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
}

run "committed_attachment_is_disabled" {
  command = plan
  assert {
    condition     = output.hub_to_spoke_peering_id == null && output.spoke_to_hub_peering_id == null && length(output.private_dns_spoke_link_ids) == 0
    error_message = "The attachment template must be inert until names/permissions/contracts are approved."
  }
}

run "workspace_forwards_the_approved_attachment_contract" {
  command = apply
  variables {
    network_peering = {
      enabled = true, use_tfe_outputs = false, use_spoke_attachment_contract = true
      spoke_attachment_contract = {
        contract_version              = "2.0.0", owner = "central-attachment-workspace", gateway_transit_enabled = false
        hub_virtual_network_id        = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
        spoke_virtual_network_id      = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/workload/providers/Microsoft.Network/virtualNetworks/spoke"
        spoke_virtual_network_name    = "spoke", spoke_resource_group_name = "workload"
        key_vault_private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
        naming_context                = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
        private_dns_zones = {
          key_vault = {
            name = "privatelink.vaultcore.azure.net", resource_group_name = "dns", registration_enabled = false
          }
        }
      }
    }
  }
  assert {
    condition = (
      output.hub_to_spoke_peering_id != null && output.spoke_to_hub_peering_id != null &&
      toset(keys(output.private_dns_spoke_link_ids)) == toset(["key_vault"]) &&
      module.network_peering[0].peerings.hub_to_spoke.name == "hub-to-spoke" &&
      module.network_peering[0].peerings.spoke_to_hub.name == "spoke-to-hub"
    )
    error_message = "The root must wire contract mode into the actual adapter and create both peerings plus only required zone links."
  }
}
