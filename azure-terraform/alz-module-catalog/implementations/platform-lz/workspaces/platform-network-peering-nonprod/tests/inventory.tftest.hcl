# Exercises the ACTUAL committed terraform.tfvars inventory with mocked APIs.
# No inventory override: missing inputs/names or incorrectly relabelled environments fail here.
mock_provider "azapi" {
  mock_data "azapi_client_config" { defaults = { tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" } }
  mock_resource "azapi_resource" { defaults = { output = { properties = { peeringState = "Connected", provisioningState = "Succeeded" } } } }
}
mock_provider "tfe" {}
variables {
  enabled              = true
  allow_local_cli_auth = true
  deployment_controls  = { approval_reference = "NET-TEST", exclusive_ownership_verified = true, shared_hub_gate_configured = true }
}
override_data {
  target = module.attachments[0].data.tfe_outputs.hub[0]
  values = { nonsensitive_values = { "contract_version" : "0.1.0", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "hub_virtual_network_address_space" : ["10.0.0.0/16"] } }
}
override_data {
  target = module.attachments[0].data.azapi_resource.hub[0]
  values = { output = { properties = { addressSpace = { addressPrefixes = ["10.0.0.0/16"] } } } }
}
override_data {
  target = module.attachments[0].data.tfe_outputs.spoke["orders_dev"]
  values = { nonsensitive_values = { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-dev/providers/Microsoft.Network/virtualNetworks/workload-cus-dev-int-orders-vnet", "spoke_virtual_network_name" : "workload-cus-dev-int-orders-vnet", "spoke_resource_group_name" : "orders-dev", "gateway_transit_enabled" : false, "naming_context" : { "region" : "centralus", "environment" : "dev", "domain" : "internal-apps", "appcode" : "orders" }, "key_vault_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "storage_blob_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net", "private_dns_zones" : { "key_vault" : { "name" : "privatelink.vaultcore.azure.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true }, "storage_blob" : { "name" : "privatelink.blob.core.windows.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true } } }, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "dev" } } }
}
override_data {
  target = module.attachments[0].data.azapi_resource.spoke["orders_dev"]
  values = { output = { properties = { addressSpace = { addressPrefixes = ["10.21.0.0/24"] } } } }
}
override_data {
  target = module.attachments[0].data.tfe_outputs.spoke["orders_test"]
  values = { nonsensitive_values = { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-test/providers/Microsoft.Network/virtualNetworks/workload-cus-test-int-orders-vnet", "spoke_virtual_network_name" : "workload-cus-test-int-orders-vnet", "spoke_resource_group_name" : "orders-test", "gateway_transit_enabled" : false, "naming_context" : { "region" : "centralus", "environment" : "test", "domain" : "internal-apps", "appcode" : "orders" }, "key_vault_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "storage_blob_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net", "private_dns_zones" : { "key_vault" : { "name" : "privatelink.vaultcore.azure.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true }, "storage_blob" : { "name" : "privatelink.blob.core.windows.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true } } }, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "test" } } }
}
override_data {
  target = module.attachments[0].data.azapi_resource.spoke["orders_test"]
  values = { output = { properties = { addressSpace = { addressPrefixes = ["10.22.0.0/24"] } } } }
}
override_data {
  target = module.attachments[0].data.tfe_outputs.spoke["orders_uat"]
  values = { nonsensitive_values = { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-uat/providers/Microsoft.Network/virtualNetworks/workload-cus-uat-int-orders-vnet", "spoke_virtual_network_name" : "workload-cus-uat-int-orders-vnet", "spoke_resource_group_name" : "orders-uat", "gateway_transit_enabled" : false, "naming_context" : { "region" : "centralus", "environment" : "uat", "domain" : "internal-apps", "appcode" : "orders" }, "key_vault_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "storage_blob_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net", "private_dns_zones" : { "key_vault" : { "name" : "privatelink.vaultcore.azure.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true }, "storage_blob" : { "name" : "privatelink.blob.core.windows.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true } } }, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "uat" } } }
}
override_data {
  target = module.attachments[0].data.azapi_resource.spoke["orders_uat"]
  values = { output = { properties = { addressSpace = { addressPrefixes = ["10.23.0.0/24"] } } } }
}
override_data {
  target = module.attachments[0].data.tfe_outputs.spoke["orders_sandbox"]
  values = { nonsensitive_values = { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-sandbox/providers/Microsoft.Network/virtualNetworks/workload-cus-sandbox-int-orders-vnet", "spoke_virtual_network_name" : "workload-cus-sandbox-int-orders-vnet", "spoke_resource_group_name" : "orders-sandbox", "gateway_transit_enabled" : false, "naming_context" : { "region" : "centralus", "environment" : "sandbox", "domain" : "internal-apps", "appcode" : "orders" }, "key_vault_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "storage_blob_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net", "private_dns_zones" : { "key_vault" : { "name" : "privatelink.vaultcore.azure.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true }, "storage_blob" : { "name" : "privatelink.blob.core.windows.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true } } }, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "sandbox" } } }
}
override_data {
  target = module.attachments[0].data.azapi_resource.spoke["orders_sandbox"]
  values = { output = { properties = { addressSpace = { addressPrefixes = ["10.24.0.0/24"] } } } }
}
run "committed_inventory_creates_both_directions_with_explicit_names" {
  command = apply
  assert {
    condition = length(output.attachments) == 4 && alltrue([for key, attachment in output.attachments :
      attachment.environment == var.attachments[key].environment &&
      attachment.hub_to_spoke_id != null && attachment.spoke_to_hub_id != null &&
      attachment.peering_names.hub_to_spoke == "peer-hub-to-${split("/", attachment.spoke_virtual_network_id)[8]}" &&
      attachment.peering_names.spoke_to_hub == "peer-${split("/", attachment.spoke_virtual_network_id)[8]}-to-hub" &&
      length(attachment.private_dns_link_ids) == 2
    ])
    error_message = "The real root inventory must create both named directions and exact DNS links without losing producer environments."
  }
}
