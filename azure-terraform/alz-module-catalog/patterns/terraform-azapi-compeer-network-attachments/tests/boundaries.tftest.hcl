mock_provider "azapi" {
  mock_data "azapi_client_config" { defaults = { tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" } }
  mock_resource "azapi_resource" { defaults = { output = { properties = { peeringState = "Connected" } } } }
}
mock_provider "tfe" {}
variables {
  tenant_id            = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  environment          = "nonprod"
  allowed_environments = ["np1", "np2"]
  hub                  = { virtual_network_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", address_space = ["10.0.0.0/16"], organization = "Compeer-Financial-Services", workspace = "platform-connectivity" }
  attachments          = { "orders_np1" : { "environment" : "np1", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-np1/providers/Microsoft.Network/virtualNetworks/workload-cus-np1-int-orders-vnet", "address_space" : ["10.21.0.0/24"], "producer" : { "organization" : "Compeer-Financial-Services", "workspace" : "workload-orders-np1", "contract_version" : "2.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123", "peering_names" : { "hub_to_spoke" : "peer-hub-to-workload-cus-np1-int-orders-vnet", "spoke_to_hub" : "peer-workload-cus-np1-int-orders-vnet-to-hub" }, "naming_context" : { "region" : "centralus", "environment" : "np1", "domain" : "internal-apps", "appcode" : "orders" } }, "orders_np2" : { "environment" : "np2", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-np2/providers/Microsoft.Network/virtualNetworks/workload-cus-np2-int-orders-vnet", "address_space" : ["10.22.0.0/24"], "producer" : { "organization" : "Compeer-Financial-Services", "workspace" : "workload-orders-np2", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123", "peering_names" : { "hub_to_spoke" : "peer-hub-to-workload-cus-np2-int-orders-vnet", "spoke_to_hub" : "peer-workload-cus-np2-int-orders-vnet-to-hub" } } }
}
override_data {
  target = data.tfe_outputs.hub[0]
  values = { nonsensitive_values = { "contract_version" : "0.1.0", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "hub_virtual_network_address_space" : ["10.0.0.0/16"] } }
}
override_data {
  target = data.azapi_resource.hub[0]
  values = { output = { properties = { addressSpace = { addressPrefixes = ["10.0.0.0/16"] } } } }
}
override_data {
  target = data.tfe_outputs.spoke["orders_np1"]
  values = { nonsensitive_values = { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-np1/providers/Microsoft.Network/virtualNetworks/workload-cus-np1-int-orders-vnet", "spoke_virtual_network_name" : "workload-cus-np1-int-orders-vnet", "spoke_resource_group_name" : "orders-np1", "gateway_transit_enabled" : false, "naming_context" : { "region" : "centralus", "environment" : "np1", "domain" : "internal-apps", "appcode" : "orders" }, "private_dns_zones" : {} }, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "np1" } } }
}
override_data {
  target = data.azapi_resource.spoke["orders_np1"]
  values = { output = { properties = { addressSpace = { addressPrefixes = ["10.21.0.0/24"] } } } }
}
override_data {
  target = data.tfe_outputs.spoke["orders_np2"]
  values = { nonsensitive_values = { "network_attachment_contract" : { "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-np2/providers/Microsoft.Network/virtualNetworks/workload-cus-np2-int-orders-vnet", "spoke_virtual_network_name" : "workload-cus-np2-int-orders-vnet", "spoke_resource_group_name" : "orders-np2", "gateway_transit_enabled" : false, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "np2", "attachment_kind" : "workload" }, "address_space" : ["10.22.0.0/24"], "private_dns_zone_ids" : {}, "private_dns_registration_enabled" : false } } }
}
override_data {
  target = data.azapi_resource.spoke["orders_np2"]
  values = { output = { properties = { addressSpace = { addressPrefixes = ["10.22.0.0/24"] } } } }
}
run "nonprod_batch_keeps_real_v2_and_v3_environments_and_explicit_names" {
  command = apply
  assert {
    condition = (output.attachments.orders_np1.environment == "np1" && output.attachments.orders_np2.environment == "np2" &&
      length(azapi_resource.hub_to_spoke) == 2 && length(azapi_resource.spoke_to_hub) == 2 &&
      alltrue([for key, attachment in var.attachments :
        azapi_resource.hub_to_spoke[key].name == attachment.peering_names.hub_to_spoke &&
        azapi_resource.spoke_to_hub[key].name == attachment.peering_names.spoke_to_hub &&
        azapi_resource.hub_to_spoke[key].body.properties.remoteVirtualNetwork.id == attachment.spoke_virtual_network_id &&
        azapi_resource.spoke_to_hub[key].body.properties.remoteVirtualNetwork.id == var.hub.virtual_network_id
    ]))
    error_message = "Both real child resources must use the approved names/remote IDs while outputs retain each actual environment."
  }
}
run "rejects_environment_not_in_boundary_allowlist" {
  command = plan
  variables { allowed_environments = ["np1"] }
  expect_failures = [terraform_data.inventory_contract, terraform_data.producer_contract]
}
run "grouping_is_opt_in_not_a_relaxed_legacy_default" {
  command = plan
  variables { allowed_environments = null }
  expect_failures = [terraform_data.inventory_contract, terraform_data.producer_contract]
}
run "rejects_empty_allowlist_even_for_empty_inventory" {
  command = plan
  variables {
    attachments          = {}
    allowed_environments = []
  }
  expect_failures = [var.allowed_environments]
}
run "rejects_invalid_allowlist_label" {
  command = plan
  variables {
    attachments          = {}
    allowed_environments = ["NP1/other"]
  }
  expect_failures = [var.allowed_environments]
}
run "rejects_null_allowlist_member_cleanly" {
  command = plan
  variables {
    attachments          = {}
    allowed_environments = [null]
  }
  expect_failures = [var.allowed_environments]
}
run "rejects_legacy_metadata_relabelled_in_inventory" {
  command = plan
  variables { attachments = { "orders_np1" : { "environment" : "np2", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-np1/providers/Microsoft.Network/virtualNetworks/workload-cus-np1-int-orders-vnet", "address_space" : ["10.21.0.0/24"], "producer" : { "organization" : "Compeer-Financial-Services", "workspace" : "workload-orders-np1", "contract_version" : "2.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123", "peering_names" : { "hub_to_spoke" : "peer-hub-to-workload-cus-np1-int-orders-vnet", "spoke_to_hub" : "peer-workload-cus-np1-int-orders-vnet-to-hub" }, "naming_context" : { "region" : "centralus", "environment" : "np1", "domain" : "internal-apps", "appcode" : "orders" } }, "orders_np2" : { "environment" : "np2", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-np2/providers/Microsoft.Network/virtualNetworks/workload-cus-np2-int-orders-vnet", "address_space" : ["10.22.0.0/24"], "producer" : { "organization" : "Compeer-Financial-Services", "workspace" : "workload-orders-np2", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123", "peering_names" : { "hub_to_spoke" : "peer-hub-to-workload-cus-np2-int-orders-vnet", "spoke_to_hub" : "peer-workload-cus-np2-int-orders-vnet-to-hub" } } } }
  expect_failures = [terraform_data.inventory_contract, terraform_data.producer_contract]
}
run "rejects_production_producer_disguised_as_nonprod" {
  command = plan
  override_data {
    target = data.tfe_outputs.spoke["orders_np2"]
    values = { nonsensitive_values = { "network_attachment_contract" : { "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-np2/providers/Microsoft.Network/virtualNetworks/workload-cus-np2-int-orders-vnet", "spoke_virtual_network_name" : "workload-cus-np2-int-orders-vnet", "spoke_resource_group_name" : "orders-np2", "gateway_transit_enabled" : false, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "prod", "attachment_kind" : "workload" }, "address_space" : ["10.22.0.0/24"], "private_dns_zone_ids" : {}, "private_dns_registration_enabled" : false } } }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "v3_grouped_entries_must_declare_their_actual_environment" {
  command = plan
  variables { attachments = { "orders_np1" : { "environment" : "np1", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-np1/providers/Microsoft.Network/virtualNetworks/workload-cus-np1-int-orders-vnet", "address_space" : ["10.21.0.0/24"], "producer" : { "organization" : "Compeer-Financial-Services", "workspace" : "workload-orders-np1", "contract_version" : "2.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123", "peering_names" : { "hub_to_spoke" : "peer-hub-to-workload-cus-np1-int-orders-vnet", "spoke_to_hub" : "peer-workload-cus-np1-int-orders-vnet-to-hub" }, "naming_context" : { "region" : "centralus", "environment" : "np1", "domain" : "internal-apps", "appcode" : "orders" } }, "orders_np2" : { "environment" : null, "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-np2/providers/Microsoft.Network/virtualNetworks/workload-cus-np2-int-orders-vnet", "address_space" : ["10.22.0.0/24"], "producer" : { "organization" : "Compeer-Financial-Services", "workspace" : "workload-orders-np2", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123", "peering_names" : { "hub_to_spoke" : "peer-hub-to-workload-cus-np2-int-orders-vnet", "spoke_to_hub" : "peer-workload-cus-np2-int-orders-vnet-to-hub" } } } }
  expect_failures = [terraform_data.inventory_contract, terraform_data.producer_contract]
}
