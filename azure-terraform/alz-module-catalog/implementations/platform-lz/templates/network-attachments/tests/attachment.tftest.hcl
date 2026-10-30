mock_provider "azapi" {
  mock_data "azapi_client_config" { defaults = { tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" } }
  mock_resource "azapi_resource" { defaults = { output = { properties = { peeringState = "Connected" } } } }
}
mock_provider "tfe" {}
variables {
  environment               = "shared"
  tenant_id                 = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  execution_subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
}
run "generic_template_is_disabled" {
  command = plan
  assert {
    condition     = output.attachments == {} && output.environment == "shared"
    error_message = "The reusable root template must be inert until copied and approved."
  }
}
run "generic_template_requires_adoption_approval" {
  command = plan
  variables {
    enabled = true
    hub     = { virtual_network_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", address_space = ["10.0.0.0/16"], organization = "org", workspace = "platform-connectivity" }
  }
  expect_failures = [terraform_data.adoption_contract]
}
run "copied_template_wires_platform_contract_without_workload_metadata" {
  command = apply
  variables {
    enabled              = true
    allow_local_cli_auth = true
    deployment_controls  = { approval_reference = "NET-123", exclusive_ownership_verified = true, shared_hub_gate_configured = true }
    hub                  = { virtual_network_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", address_space = ["10.0.0.0/16"], organization = "org", workspace = "platform-connectivity" }
    attachments          = { "platform" : { "attachment_kind" : "platform", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/platform-services/providers/Microsoft.Network/virtualNetworks/platform-services-shared-vnet", "address_space" : ["10.40.0.0/24"], "producer" : { "organization" : "Compeer-Financial-Services", "workspace" : "platform-services-owner", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123", "private_dns_zone_ids" : { "storage_file" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" } } }
  }
  override_data {
    target = module.attachments[0].data.tfe_outputs.hub[0]
    values = { nonsensitive_values = { "contract_version" : "0.1.0", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "hub_virtual_network_address_space" : ["10.0.0.0/16"] } }
  }
  override_data {
    target = module.attachments[0].data.tfe_outputs.spoke["platform"]
    values = { nonsensitive_values = { network_attachment_contract = { "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/platform-services/providers/Microsoft.Network/virtualNetworks/platform-services-shared-vnet", "spoke_virtual_network_name" : "platform-services-shared-vnet", "spoke_resource_group_name" : "platform-services", "address_space" : ["10.40.0.0/24"], "gateway_transit_enabled" : false, "private_dns_zone_ids" : { "storage_file" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" }, "private_dns_registration_enabled" : false, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", "environment" : "shared", "attachment_kind" : "platform" } } } }
  }
  override_data {
    target = module.attachments[0].data.azapi_resource.hub[0]
    values = { output = { properties = { addressSpace = { addressPrefixes = ["10.0.0.0/16"] } } } }
  }
  override_data {
    target = module.attachments[0].data.azapi_resource.spoke["platform"]
    values = { output = { properties = { addressSpace = { addressPrefixes = ["10.40.0.0/24"] } } } }
  }
  assert {
    condition     = output.attachments.platform.attachment_kind == "platform" && output.attachments.platform.environment == "shared" && length(output.attachments.platform.private_dns_link_ids) == 1
    error_message = "The independent platform root must compose the real batch pattern with no fake appcode/domain."
  }
}
