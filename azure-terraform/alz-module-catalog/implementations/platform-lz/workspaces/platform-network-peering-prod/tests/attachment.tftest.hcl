mock_provider "azapi" {
  mock_data "azapi_client_config" { defaults = { tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" } }
  mock_resource "azapi_resource" { defaults = { output = { properties = { peeringState = "Connected" } } } }
}
mock_provider "tfe" {}
variables {
  reserved_address_spaces   = []
  tenant_id                 = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  execution_subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
}
run "new_root_is_inert" {
  command = plan
  assert {
    condition     = output.attachments == {} && output.environment == "prod"
    error_message = "The new state must be inert and bound to its own environment."
  }
}
run "rejects_unapproved_adoption" {
  command = plan
  variables {
    enabled = true
    hub = {
      virtual_network_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet"
      address_space      = ["10.0.0.0/16"]
      organization       = "Compeer-Financial-Services"
      workspace          = "platform-connectivity"
    }
  }
  expect_failures = [terraform_data.adoption_contract]
}
run "root_wires_approved_cross_subscription_attachment" {
  command = apply
  variables {
    enabled              = true
    allow_local_cli_auth = true
    deployment_controls  = { approval_reference = "NET-123", exclusive_ownership_verified = true, shared_hub_gate_configured = true }
    hub = {
      virtual_network_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet"
      address_space      = ["10.0.0.0/16"]
      organization       = "Compeer-Financial-Services"
      workspace          = "platform-connectivity"
    }
    attachments = {
      orders = {
        spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet"
        address_space            = ["10.20.0.0/24"]
        producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod" }
        naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
        approval_reference       = "NET-123"
        ipam_reference           = "IPAM-123"
        private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
      }
    }
  }
  override_data {
    target = module.attachments[0].data.tfe_outputs.hub[0]
    values = { nonsensitive_values = { "contract_version" : "0.1.0", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "hub_virtual_network_address_space" : ["10.0.0.0/16"] } }
  }
  override_data {
    target = module.attachments[0].data.tfe_outputs.spoke["orders"]
    values = { nonsensitive_values = { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet", "spoke_virtual_network_name" : "orders-prod-vnet", "spoke_resource_group_name" : "orders", "gateway_transit_enabled" : false, "naming_context" : { "region" : "centralus", "environment" : "prod", "domain" : "internal-apps", "appcode" : "orders" }, "key_vault_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "private_dns_zones" : { "key_vault" : { "name" : "privatelink.vaultcore.azure.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true } } }, "spoke" : { "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "prod" } } } }
  }
  override_data {
    target = module.attachments[0].data.azapi_resource.hub[0]
    values = { output = { properties = { addressSpace = { addressPrefixes = ["10.0.0.0/16"] } } } }
  }
  override_data {
    target = module.attachments[0].data.azapi_resource.spoke["orders"]
    values = { output = { properties = { addressSpace = { addressPrefixes = ["10.20.0.0/24"] } } } }
  }
  assert {
    condition     = length(output.attachments) == 1 && output.attachments.orders.hub_to_spoke_id != null && output.attachments.orders.spoke_to_hub_id != null && length(output.attachments.orders.private_dns_link_ids) == 1
    error_message = "The root must wire the real batch child and exact approved zone link."
  }
}
