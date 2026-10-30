mock_provider "azapi" {
  mock_data "azapi_client_config" { defaults = { tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" } }
  mock_resource "azapi_resource" { defaults = { output = { properties = { peeringState = "Connected", provisioningState = "Succeeded" } } } }
}
mock_provider "tfe" {}
run "mixed_platform_v3_and_existing_workload_v2_preserve_their_interfaces" {
  command = apply
  variables {
    environment = "prod"
    attachments = { "platform" : { "attachment_kind" : "platform", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/platform-services/providers/Microsoft.Network/virtualNetworks/platform-services-prod-vnet", "address_space" : ["10.40.0.0/24"], "producer" : { "organization" : "Compeer-Financial-Services", "workspace" : "platform-services-owner", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123", "private_dns_zone_ids" : { "storage_file" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" } }, "orders" : { "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet", "address_space" : ["10.20.0.0/24"], "producer" : { "organization" : "org", "workspace" : "orders-prod", "contract_version" : "2.0.0" }, "naming_context" : { "region" : "centralus", "environment" : "prod", "domain" : "internal-apps", "appcode" : "orders" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123", "private_dns_zone_ids" : { "key_vault" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" } } }
  }
  override_data {
    target = data.tfe_outputs.spoke["platform"]
    values = { nonsensitive_values = { network_attachment_contract = { "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/platform-services/providers/Microsoft.Network/virtualNetworks/platform-services-prod-vnet", "spoke_virtual_network_name" : "platform-services-prod-vnet", "spoke_resource_group_name" : "platform-services", "address_space" : ["10.40.0.0/24"], "gateway_transit_enabled" : false, "private_dns_zone_ids" : { "storage_file" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" }, "private_dns_registration_enabled" : false, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", "environment" : "prod", "attachment_kind" : "platform" } } } }
  }
  override_data {
    target = data.tfe_outputs.spoke["orders"]
    values = { nonsensitive_values = { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet", "spoke_virtual_network_name" : "orders-prod-vnet", "spoke_resource_group_name" : "orders", "gateway_transit_enabled" : false, "naming_context" : { "region" : "centralus", "environment" : "prod", "domain" : "internal-apps", "appcode" : "orders" }, "key_vault_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "private_dns_zones" : { "key_vault" : { "name" : "privatelink.vaultcore.azure.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true } } }, "spoke" : { "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "prod" } } } }
  }
  override_data {
    target = data.azapi_resource.spoke["orders"]
    values = { output = { properties = { addressSpace = { addressPrefixes = ["10.20.0.0/24"] } } } }
  }
  assert {
    condition     = length(azapi_resource.hub_to_spoke) == 2 && output.attachments.platform.attachment_kind == "platform" && output.attachments.orders.attachment_kind == "workload" && output.attachments.orders.peering_names.hub_to_spoke == "shared-hub-vnet-to-orders-prod-vnet"
    error_message = "A compatible approved boundary must handle v2/v3 platform/workload producers without changing existing attachment names."
  }
}

variables {
  tenant_id   = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  environment = "shared"
  hub         = { virtual_network_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", address_space = ["10.0.0.0/16"], organization = "Compeer-Financial-Services", workspace = "platform-connectivity" }
  attachments = { "platform" : { "attachment_kind" : "platform", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/platform-services/providers/Microsoft.Network/virtualNetworks/platform-services-shared-vnet", "address_space" : ["10.40.0.0/24"], "producer" : { "organization" : "Compeer-Financial-Services", "workspace" : "platform-services-owner", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123", "private_dns_zone_ids" : { "storage_file" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" } } }
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
  target = data.tfe_outputs.spoke["platform"]
  values = { nonsensitive_values = { network_attachment_contract = { "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/platform-services/providers/Microsoft.Network/virtualNetworks/platform-services-shared-vnet", "spoke_virtual_network_name" : "platform-services-shared-vnet", "spoke_resource_group_name" : "platform-services", "address_space" : ["10.40.0.0/24"], "gateway_transit_enabled" : false, "private_dns_zone_ids" : { "storage_file" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" }, "private_dns_registration_enabled" : false, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", "environment" : "shared", "attachment_kind" : "platform" } } } }
}
override_data {
  target = data.azapi_resource.spoke["platform"]
  values = { output = { properties = { addressSpace = { addressPrefixes = ["10.40.0.0/24"] } } } }
}
run "generic_producer_publishes_real_vnet_metadata_without_resources" {
  command = apply
  module { source = "./producer" }
  variables {
    tenant_id              = "cccccccc-cccc-cccc-cccc-cccccccccccc"
    environment            = "shared"
    attachment_kind        = "platform"
    hub_virtual_network_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet"
    virtual_network        = { id = "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/platform-services/providers/Microsoft.Network/virtualNetworks/platform-services-shared-vnet", address_space = ["10.40.0.0/24"] }
    private_dns_zone_ids   = { storage_file = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" }
  }
  assert {
    condition     = jsonencode(output.network_attachment_contract) == jsonencode({ "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/platform-services/providers/Microsoft.Network/virtualNetworks/platform-services-shared-vnet", "spoke_virtual_network_name" : "platform-services-shared-vnet", "spoke_resource_group_name" : "platform-services", "address_space" : ["10.40.0.0/24"], "gateway_transit_enabled" : false, "private_dns_zone_ids" : { "storage_file" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" }, "private_dns_registration_enabled" : false, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", "environment" : "shared", "attachment_kind" : "platform" } })
    error_message = "The output-only adapter must derive its network metadata from the real owner outputs."
  }
}
run "platform_vnet_uses_generic_contract_without_appcode_or_domain" {
  command = apply
  assert {
    condition     = length(azapi_resource.hub_to_spoke) == 1 && length(azapi_resource.spoke_to_hub) == 1 && azapi_resource.dns_link["platform/storage_file"].parent_id == "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" && output.attachments.platform.attachment_kind == "platform" && output.attachments.platform.environment == "shared"
    error_message = "A platform VNet must not need workload naming metadata or a workload-only DNS key."
  }
}
run "rejects_cross_environment_platform_contract" {
  command = plan
  variables { environment = "prod" }
  expect_failures = [terraform_data.producer_contract]
}
run "rejects_platform_relabelled_as_workload" {
  command = plan
  variables { attachments = { platform = merge({ "attachment_kind" : "platform", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/platform-services/providers/Microsoft.Network/virtualNetworks/platform-services-shared-vnet", "address_space" : ["10.40.0.0/24"], "producer" : { "organization" : "Compeer-Financial-Services", "workspace" : "platform-services-owner", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123", "private_dns_zone_ids" : { "storage_file" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" } }, { attachment_kind = "workload" }) } }
  expect_failures = [terraform_data.producer_contract]
}
run "rejects_generic_producer_cidr_drift" {
  command = plan
  override_data {
    target = data.tfe_outputs.spoke["platform"]
    values = { nonsensitive_values = { "network_attachment_contract" : { "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/platform-services/providers/Microsoft.Network/virtualNetworks/platform-services-shared-vnet", "spoke_virtual_network_name" : "platform-services-shared-vnet", "spoke_resource_group_name" : "platform-services", "address_space" : ["10.41.0.0/24"], "gateway_transit_enabled" : false, "private_dns_zone_ids" : { "storage_file" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" }, "private_dns_registration_enabled" : false, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", "environment" : "shared", "attachment_kind" : "platform" } } } }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "rejects_unapproved_generic_dns" {
  command = plan
  variables { attachments = { platform = merge({ "attachment_kind" : "platform", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/platform-services/providers/Microsoft.Network/virtualNetworks/platform-services-shared-vnet", "address_space" : ["10.40.0.0/24"], "producer" : { "organization" : "Compeer-Financial-Services", "workspace" : "platform-services-owner", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123", "private_dns_zone_ids" : { "storage_file" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" } }, { private_dns_zone_ids = {} }) } }
  expect_failures = [terraform_data.producer_contract]
}
run "rejects_generic_dns_auto_registration" {
  command = plan
  override_data {
    target = data.tfe_outputs.spoke["platform"]
    values = { nonsensitive_values = { "network_attachment_contract" : { "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/platform-services/providers/Microsoft.Network/virtualNetworks/platform-services-shared-vnet", "spoke_virtual_network_name" : "platform-services-shared-vnet", "spoke_resource_group_name" : "platform-services", "address_space" : ["10.40.0.0/24"], "gateway_transit_enabled" : false, "private_dns_zone_ids" : { "storage_file" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" }, "private_dns_registration_enabled" : true, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", "environment" : "shared", "attachment_kind" : "platform" } } } }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "rejects_missing_generic_public_output" {
  command = plan
  override_data {
    target = data.tfe_outputs.spoke["platform"]
    values = { nonsensitive_values = { "attachment_contract" : { "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/platform-services/providers/Microsoft.Network/virtualNetworks/platform-services-shared-vnet", "spoke_virtual_network_name" : "platform-services-shared-vnet", "spoke_resource_group_name" : "platform-services", "address_space" : ["10.40.0.0/24"], "gateway_transit_enabled" : false, "private_dns_zone_ids" : { "storage_file" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" }, "private_dns_registration_enabled" : false, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", "environment" : "shared", "attachment_kind" : "platform" } } } }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "rejects_platform_contract_using_workload_v2" {
  command = plan
  variables { attachments = { platform = merge({ "attachment_kind" : "platform", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/platform-services/providers/Microsoft.Network/virtualNetworks/platform-services-shared-vnet", "address_space" : ["10.40.0.0/24"], "producer" : { "organization" : "Compeer-Financial-Services", "workspace" : "platform-services-owner", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123", "private_dns_zone_ids" : { "storage_file" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net" } }, { producer = { organization = "org", workspace = "platform-services-owner", contract_version = "2.0.0" }, naming_context = { region = "centralus", environment = "shared", domain = "platform", appcode = "services" } }) } }
  expect_failures = [var.attachments]
}
run "rejects_invalid_boundary_label" {
  command = plan
  variables { environment = "Prod/Other" }
  expect_failures = [var.environment]
}
run "only_existing_app_environments_prod_creates_3_pairs" {
  command = apply
  variables {
    environment = "prod"
    attachments = { "accounts" : { "attachment_kind" : "workload", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/accounts/providers/Microsoft.Network/virtualNetworks/accounts-prod-vnet", "address_space" : ["10.50.0.0/24"], "producer" : { "organization" : "org", "workspace" : "workload-accounts-prod", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123" }, "claims" : { "attachment_kind" : "workload", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/claims/providers/Microsoft.Network/virtualNetworks/claims-prod-vnet", "address_space" : ["10.51.0.0/24"], "producer" : { "organization" : "org", "workspace" : "workload-claims-prod", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123" }, "loans" : { "attachment_kind" : "workload", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/loans/providers/Microsoft.Network/virtualNetworks/loans-prod-vnet", "address_space" : ["10.52.0.0/24"], "producer" : { "organization" : "org", "workspace" : "workload-loans-prod", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123" } }
  }
  override_data {
    target = data.tfe_outputs.spoke["accounts"]
    values = { nonsensitive_values = { network_attachment_contract = { "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/accounts/providers/Microsoft.Network/virtualNetworks/accounts-prod-vnet", "spoke_virtual_network_name" : "accounts-prod-vnet", "spoke_resource_group_name" : "accounts", "address_space" : ["10.50.0.0/24"], "gateway_transit_enabled" : false, "private_dns_zone_ids" : {}, "private_dns_registration_enabled" : false, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", "environment" : "prod", "attachment_kind" : "workload" } } } }
  }
  override_data {
    target = data.azapi_resource.spoke["accounts"]
    values = { output = { properties = { addressSpace = { addressPrefixes = ["10.50.0.0/24"] } } } }
  }
  override_data {
    target = data.tfe_outputs.spoke["claims"]
    values = { nonsensitive_values = { network_attachment_contract = { "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/claims/providers/Microsoft.Network/virtualNetworks/claims-prod-vnet", "spoke_virtual_network_name" : "claims-prod-vnet", "spoke_resource_group_name" : "claims", "address_space" : ["10.51.0.0/24"], "gateway_transit_enabled" : false, "private_dns_zone_ids" : {}, "private_dns_registration_enabled" : false, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", "environment" : "prod", "attachment_kind" : "workload" } } } }
  }
  override_data {
    target = data.azapi_resource.spoke["claims"]
    values = { output = { properties = { addressSpace = { addressPrefixes = ["10.51.0.0/24"] } } } }
  }
  override_data {
    target = data.tfe_outputs.spoke["loans"]
    values = { nonsensitive_values = { network_attachment_contract = { "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/loans/providers/Microsoft.Network/virtualNetworks/loans-prod-vnet", "spoke_virtual_network_name" : "loans-prod-vnet", "spoke_resource_group_name" : "loans", "address_space" : ["10.52.0.0/24"], "gateway_transit_enabled" : false, "private_dns_zone_ids" : {}, "private_dns_registration_enabled" : false, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", "environment" : "prod", "attachment_kind" : "workload" } } } }
  }
  override_data {
    target = data.azapi_resource.spoke["loans"]
    values = { output = { properties = { addressSpace = { addressPrefixes = ["10.52.0.0/24"] } } } }
  }
  assert {
    condition     = length(azapi_resource.hub_to_spoke) == 3 && length(azapi_resource.spoke_to_hub) == 3 && length(azapi_resource.dns_link) == 0
    error_message = "Create only declared app/environment instances, not a four-environment Cartesian product."
  }
}
run "only_existing_app_environments_dev_creates_2_pairs" {
  command = apply
  variables {
    environment = "dev"
    attachments = { "claims" : { "attachment_kind" : "workload", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/claims/providers/Microsoft.Network/virtualNetworks/claims-dev-vnet", "address_space" : ["10.51.0.0/24"], "producer" : { "organization" : "org", "workspace" : "workload-claims-dev", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123" }, "loans" : { "attachment_kind" : "workload", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/loans/providers/Microsoft.Network/virtualNetworks/loans-dev-vnet", "address_space" : ["10.52.0.0/24"], "producer" : { "organization" : "org", "workspace" : "workload-loans-dev", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123" } }
  }
  override_data {
    target = data.tfe_outputs.spoke["claims"]
    values = { nonsensitive_values = { network_attachment_contract = { "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/claims/providers/Microsoft.Network/virtualNetworks/claims-dev-vnet", "spoke_virtual_network_name" : "claims-dev-vnet", "spoke_resource_group_name" : "claims", "address_space" : ["10.51.0.0/24"], "gateway_transit_enabled" : false, "private_dns_zone_ids" : {}, "private_dns_registration_enabled" : false, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", "environment" : "dev", "attachment_kind" : "workload" } } } }
  }
  override_data {
    target = data.azapi_resource.spoke["claims"]
    values = { output = { properties = { addressSpace = { addressPrefixes = ["10.51.0.0/24"] } } } }
  }
  override_data {
    target = data.tfe_outputs.spoke["loans"]
    values = { nonsensitive_values = { network_attachment_contract = { "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/loans/providers/Microsoft.Network/virtualNetworks/loans-dev-vnet", "spoke_virtual_network_name" : "loans-dev-vnet", "spoke_resource_group_name" : "loans", "address_space" : ["10.52.0.0/24"], "gateway_transit_enabled" : false, "private_dns_zone_ids" : {}, "private_dns_registration_enabled" : false, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", "environment" : "dev", "attachment_kind" : "workload" } } } }
  }
  override_data {
    target = data.azapi_resource.spoke["loans"]
    values = { output = { properties = { addressSpace = { addressPrefixes = ["10.52.0.0/24"] } } } }
  }
  assert {
    condition     = length(azapi_resource.hub_to_spoke) == 2 && length(azapi_resource.spoke_to_hub) == 2 && length(azapi_resource.dns_link) == 0
    error_message = "Create only declared app/environment instances, not a four-environment Cartesian product."
  }
}
run "only_existing_app_environments_perf_creates_1_pairs" {
  command = apply
  variables {
    environment = "perf"
    attachments = { "loans" : { "attachment_kind" : "workload", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/loans/providers/Microsoft.Network/virtualNetworks/loans-perf-vnet", "address_space" : ["10.52.0.0/24"], "producer" : { "organization" : "org", "workspace" : "workload-loans-perf", "contract_version" : "3.0.0" }, "approval_reference" : "NET-123", "ipam_reference" : "IPAM-123" } }
  }
  override_data {
    target = data.tfe_outputs.spoke["loans"]
    values = { nonsensitive_values = { network_attachment_contract = { "contract_version" : "3.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee/resourceGroups/loans/providers/Microsoft.Network/virtualNetworks/loans-perf-vnet", "spoke_virtual_network_name" : "loans-perf-vnet", "spoke_resource_group_name" : "loans", "address_space" : ["10.52.0.0/24"], "gateway_transit_enabled" : false, "private_dns_zone_ids" : {}, "private_dns_registration_enabled" : false, "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", "environment" : "perf", "attachment_kind" : "workload" } } } }
  }
  override_data {
    target = data.azapi_resource.spoke["loans"]
    values = { output = { properties = { addressSpace = { addressPrefixes = ["10.52.0.0/24"] } } } }
  }
  assert {
    condition     = length(azapi_resource.hub_to_spoke) == 1 && length(azapi_resource.spoke_to_hub) == 1 && length(azapi_resource.dns_link) == 0
    error_message = "Create only declared app/environment instances, not a four-environment Cartesian product."
  }
}
