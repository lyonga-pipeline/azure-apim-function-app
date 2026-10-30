mock_provider "azapi" {
  mock_data "azapi_client_config" { defaults = { tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" } }
  mock_resource "azapi_resource" {
    defaults = { output = { properties = { peeringState = "Connected", provisioningState = "Succeeded" } } }
  }
}
mock_provider "tfe" {}

run "approved_gateway_transit_is_paired" {
  command = apply
  variables {
    hub = { virtual_network_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", address_space = ["10.0.0.0/16"], organization = "Compeer-Financial-Services", workspace = "platform-connectivity", gateway_ready = true }
    attachments = { orders = merge({
      spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet"
      address_space            = ["10.20.0.0/24"]
      producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod" }
      naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
      approval_reference       = "NET-123"
      ipam_reference           = "IPAM-orders"
      private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
    }, { gateway_transit = true }) }
  }
  override_data {
    target = data.tfe_outputs.spoke["orders"]
    values = { nonsensitive_values = { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet", "spoke_virtual_network_name" : "orders-prod-vnet", "spoke_resource_group_name" : "orders", "gateway_transit_enabled" : true, "naming_context" : { "region" : "centralus", "environment" : "prod", "domain" : "internal-apps", "appcode" : "orders" }, "key_vault_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "private_dns_zones" : { "key_vault" : { "name" : "privatelink.vaultcore.azure.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true } } }, "spoke" : { "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "prod" } } } }
  }
  assert {
    condition     = azapi_resource.hub_to_spoke["orders"].body.properties.allowGatewayTransit && azapi_resource.spoke_to_hub["orders"].body.properties.useRemoteGateways && !azapi_resource.hub_to_spoke["orders"].body.properties.useRemoteGateways && !azapi_resource.spoke_to_hub["orders"].body.properties.allowGatewayTransit
    error_message = "Only the hub offers transit and only the spoke consumes it."
  }
}
run "approved_existing_names_are_preserved" {
  command = apply
  variables {
    attachments = {
      orders = merge({
        spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet"
        address_space            = ["10.20.0.0/24"]
        producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod" }
        naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
        approval_reference       = "NET-123"
        ipam_reference           = "IPAM-orders"
        private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
        }, {
        peering_names          = { hub_to_spoke = "approved-existing-hub-orders", spoke_to_hub = "approved-existing-orders-hub" }
        private_dns_link_names = { key_vault = "approved-existing-orders-link" }
      })
    }
  }
  assert {
    condition     = azapi_resource.hub_to_spoke["orders"].name == "approved-existing-hub-orders" && azapi_resource.spoke_to_hub["orders"].name == "approved-existing-orders-hub" && azapi_resource.dns_link["orders/key_vault"].name == "approved-existing-orders-link"
    error_message = "Migration must preserve approved Azure child names."
  }
}
run "no_zone_links_only_when_producer_requests_none" {
  command = apply
  variables {
    attachments = { orders = merge({
      spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet"
      address_space            = ["10.20.0.0/24"]
      producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod" }
      naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
      approval_reference       = "NET-123"
      ipam_reference           = "IPAM-orders"
      private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
    }, { private_dns_zone_ids = {} }) }
  }
  override_data {
    target = data.tfe_outputs.spoke["orders"]
    values = { nonsensitive_values = { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet", "spoke_virtual_network_name" : "orders-prod-vnet", "spoke_resource_group_name" : "orders", "gateway_transit_enabled" : false, "naming_context" : { "region" : "centralus", "environment" : "prod", "domain" : "internal-apps", "appcode" : "orders" }, "key_vault_private_dns_zone_id" : null, "private_dns_zones" : {} }, "spoke" : { "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "prod" } } } }
  }
  assert {
    condition     = length(azapi_resource.dns_link) == 0 && length(azapi_resource.hub_to_spoke) == 1 && length(azapi_resource.spoke_to_hub) == 1
    error_message = "DNS opt-out must not suppress either peering direction."
  }
}
run "vault_and_blob_zones_use_exact_approved_ids" {
  command = apply
  variables {
    attachments = { orders = merge({
      spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet"
      address_space            = ["10.20.0.0/24"]
      producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod" }
      naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
      approval_reference       = "NET-123"
      ipam_reference           = "IPAM-orders"
      private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
    }, { private_dns_zone_ids = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", storage_blob = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net" } }) }
  }
  override_data {
    target = data.tfe_outputs.spoke["orders"]
    values = { nonsensitive_values = { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet", "spoke_virtual_network_name" : "orders-prod-vnet", "spoke_resource_group_name" : "orders", "gateway_transit_enabled" : false, "naming_context" : { "region" : "centralus", "environment" : "prod", "domain" : "internal-apps", "appcode" : "orders" }, "key_vault_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "private_dns_zones" : { "key_vault" : { "name" : "privatelink.vaultcore.azure.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true }, "storage_blob" : { "name" : "privatelink.blob.core.windows.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true } }, "storage_blob_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net" }, "spoke" : { "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "prod" } } } }
  }
  assert {
    condition     = length(azapi_resource.dns_link) == 2 && azapi_resource.dns_link["orders/storage_blob"].parent_id == "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    error_message = "Both requested private service zones must resolve to reviewed central zone IDs."
  }
}

variables {
  tenant_id   = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  environment = "prod"
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
      ipam_reference           = "IPAM-orders"
      private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
    }
    claims = {
      spoke_virtual_network_id = "/subscriptions/dddddddd-dddd-dddd-dddd-dddddddddddd/resourceGroups/claims/providers/Microsoft.Network/virtualNetworks/claims-prod-vnet"
      address_space            = ["10.21.0.0/24"]
      producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-claims-prod" }
      naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "claims" }
      approval_reference       = "NET-123"
      ipam_reference           = "IPAM-claims"
      private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
    }
  }
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
  target = data.tfe_outputs.spoke["orders"]
  values = { nonsensitive_values = { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet", "spoke_virtual_network_name" : "orders-prod-vnet", "spoke_resource_group_name" : "orders", "gateway_transit_enabled" : false, "naming_context" : { "region" : "centralus", "environment" : "prod", "domain" : "internal-apps", "appcode" : "orders" }, "key_vault_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "private_dns_zones" : { "key_vault" : { "name" : "privatelink.vaultcore.azure.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true } } }, "spoke" : { "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "prod" } } } }
}
override_data {
  target = data.azapi_resource.spoke["orders"]
  values = { output = { properties = { addressSpace = { addressPrefixes = ["10.20.0.0/24"] } } } }
}
override_data {
  target = data.tfe_outputs.spoke["claims"]
  values = { nonsensitive_values = { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/dddddddd-dddd-dddd-dddd-dddddddddddd/resourceGroups/claims/providers/Microsoft.Network/virtualNetworks/claims-prod-vnet", "spoke_virtual_network_name" : "claims-prod-vnet", "spoke_resource_group_name" : "claims", "gateway_transit_enabled" : false, "naming_context" : { "region" : "centralus", "environment" : "prod", "domain" : "internal-apps", "appcode" : "claims" }, "key_vault_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "private_dns_zones" : { "key_vault" : { "name" : "privatelink.vaultcore.azure.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true } } }, "spoke" : { "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "dddddddd-dddd-dddd-dddd-dddddddddddd", "environment" : "prod" } } } }
}
override_data {
  target = data.azapi_resource.spoke["claims"]
  values = { output = { properties = { addressSpace = { addressPrefixes = ["10.21.0.0/24"] } } } }
}
run "multiple_subscriptions_one_provider_owns_only_children" {
  command = apply
  assert {
    condition     = length(azapi_resource.hub_to_spoke) == 2 && length(azapi_resource.spoke_to_hub) == 2 && length(azapi_resource.dns_link) == 2
    error_message = "Each approved attachment needs both directions and its exact approved DNS links."
  }
  assert {
    condition     = azapi_resource.hub_to_spoke["orders"].parent_id == var.hub.virtual_network_id && azapi_resource.spoke_to_hub["orders"].parent_id == var.attachments.orders.spoke_virtual_network_id && azapi_resource.spoke_to_hub["claims"].parent_id == var.attachments.claims.spoke_virtual_network_id
    error_message = "Full parent IDs must support distinct subscriptions without provider aliases."
  }
  assert {
    condition     = alltrue([for peering in values(azapi_resource.hub_to_spoke) : !peering.body.properties.useRemoteGateways && !peering.body.properties.allowGatewayTransit && peering.locks == tolist([lower(var.hub.virtual_network_id)])]) && alltrue([for peering in values(azapi_resource.spoke_to_hub) : !peering.body.properties.useRemoteGateways && !peering.body.properties.allowGatewayTransit && peering.locks == tolist([lower(var.hub.virtual_network_id)])])
    error_message = "Transit defaults off and every peering mutation uses the common provider-process mutex."
  }
  assert {
    condition     = alltrue([for link in values(azapi_resource.dns_link) : !link.body.properties.registrationEnabled && link.parent_id == "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"]) && output.attachments.orders.peering_names.hub_to_spoke == "shared-hub-vnet-to-orders-prod-vnet"
    error_message = "PE zones cannot auto-register and central names must follow the canonical naming contract."
  }
}
run "empty_inventory_is_inert" {
  command = plan
  variables { attachments = {} }
  assert {
    condition     = length(data.tfe_outputs.hub) == 0 && length(data.tfe_outputs.spoke) == 0 && length(data.azapi_resource.hub) == 0 && length(azapi_resource.hub_to_spoke) == 0 && output.attachments == {}
    error_message = "An empty root must not read producers/Azure or create attachments."
  }
}
run "rejects_wrong_environment" {
  command = plan
  variables {
    environment = "np1"
  }
  expect_failures = [terraform_data.inventory_contract, terraform_data.producer_contract]
}
run "rejects_hub_gateway_not_ready" {
  command = plan
  variables {
    attachments = { orders = merge({
      spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet"
      address_space            = ["10.20.0.0/24"]
      producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod" }
      naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
      approval_reference       = "NET-123"
      ipam_reference           = "IPAM-orders"
      private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
    }, { gateway_transit = true }) }
  }
  expect_failures = [terraform_data.inventory_contract, terraform_data.producer_contract]
}
run "rejects_duplicate_spoke_ids" {
  command = plan
  variables {
    attachments = { orders = {
      spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet"
      address_space            = ["10.20.0.0/24"]
      producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod" }
      naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
      approval_reference       = "NET-123"
      ipam_reference           = "IPAM-orders"
      private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
      }, claims = {
      spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet"
      address_space            = ["10.20.0.0/24"]
      producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod" }
      naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
      approval_reference       = "NET-123"
      ipam_reference           = "IPAM-orders"
      private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
    } }
  }
  expect_failures = [terraform_data.inventory_contract, terraform_data.producer_contract, terraform_data.ipam_contract]
}
run "rejects_reserved_ipam_overlap" {
  command = plan
  variables {
    reserved_address_spaces = ["10.20.0.128/25"]
  }
  expect_failures = [terraform_data.ipam_contract]
}
run "rejects_overlapping_spokes" {
  command = plan
  variables {
    attachments = { orders = {
      spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet"
      address_space            = ["10.20.0.0/24"]
      producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod" }
      naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
      approval_reference       = "NET-123"
      ipam_reference           = "IPAM-orders"
      private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
      }, claims = merge({
        spoke_virtual_network_id = "/subscriptions/dddddddd-dddd-dddd-dddd-dddddddddddd/resourceGroups/claims/providers/Microsoft.Network/virtualNetworks/claims-prod-vnet"
        address_space            = ["10.21.0.0/24"]
        producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-claims-prod" }
        naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "claims" }
        approval_reference       = "NET-123"
        ipam_reference           = "IPAM-claims"
        private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
    }, { address_space = ["10.20.0.128/25"] }) }
  }
  expect_failures = [terraform_data.ipam_contract, terraform_data.producer_contract]
}
run "rejects_unapproved_dns" {
  command = plan
  variables {
    attachments = { orders = merge({
      spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet"
      address_space            = ["10.20.0.0/24"]
      producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod" }
      naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
      approval_reference       = "NET-123"
      ipam_reference           = "IPAM-orders"
      private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
    }, { private_dns_zone_ids = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/other-dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" } }) }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "rejects_missing_dns_link_intent" {
  command = plan
  variables {
    attachments = { orders = merge({
      spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet"
      address_space            = ["10.20.0.0/24"]
      producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod" }
      naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
      approval_reference       = "NET-123"
      ipam_reference           = "IPAM-orders"
      private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
    }, { private_dns_zone_ids = {} }) }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "rejects_unsupported_spoke_contract" {
  command = plan
  variables {
    attachments = { orders = merge({
      spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet"
      address_space            = ["10.20.0.0/24"]
      producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod" }
      naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
      approval_reference       = "NET-123"
      ipam_reference           = "IPAM-orders"
      private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
    }, { producer = { organization = "org", workspace = "workload-orders-prod", contract_version = "9.0.0" } }) }
  }
  expect_failures = [var.attachments]
}
run "rejects_empty_approval" {
  command = plan
  variables {
    attachments = { orders = merge({
      spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet"
      address_space            = ["10.20.0.0/24"]
      producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod" }
      naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
      approval_reference       = "NET-123"
      ipam_reference           = "IPAM-orders"
      private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
    }, { approval_reference = "" }) }
  }
  expect_failures = [var.attachments]
}
run "rejects_unused_dns_name_override" {
  command = plan
  variables {
    attachments = { orders = merge({
      spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet"
      address_space            = ["10.20.0.0/24"]
      producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-prod" }
      naming_context           = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
      approval_reference       = "NET-123"
      ipam_reference           = "IPAM-orders"
      private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
    }, { private_dns_link_names = { extra = "extra-link" } }) }
  }
  expect_failures = [var.attachments]
}
run "rejects_provider_tenant" {
  command = plan
  override_data {
    target = data.azapi_client_config.current[0]
    values = { "tenant_id" : "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee" }
  }
  expect_failures = [terraform_data.inventory_contract]
}
run "rejects_hub_producer_drift" {
  command = plan
  override_data {
    target = data.tfe_outputs.hub[0]
    values = { "nonsensitive_values" : { "contract_version" : "0.1.0", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet-changed", "hub_virtual_network_address_space" : ["10.0.0.0/16"] } }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "rejects_live_hub_cidr_drift" {
  command = plan
  override_data {
    target = data.azapi_resource.hub[0]
    values = { "output" : { "properties" : { "addressSpace" : { "addressPrefixes" : ["10.1.0.0/16"] } } } }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "rejects_live_spoke_cidr_drift" {
  command = plan
  override_data {
    target = data.azapi_resource.spoke["orders"]
    values = { "output" : { "properties" : { "addressSpace" : { "addressPrefixes" : ["10.25.0.0/24"] } } } }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "rejects_unapproved_spoke_rebuild" {
  command = plan
  override_data {
    target = data.tfe_outputs.spoke["orders"]
    values = { "nonsensitive_values" : { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet-rebuilt", "spoke_virtual_network_name" : "orders-prod-vnet", "spoke_resource_group_name" : "orders", "gateway_transit_enabled" : false, "naming_context" : { "region" : "centralus", "environment" : "prod", "domain" : "internal-apps", "appcode" : "orders" }, "key_vault_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "private_dns_zones" : { "key_vault" : { "name" : "privatelink.vaultcore.azure.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true } } }, "spoke" : { "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "prod" } } } }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "rejects_split_owner" {
  command = plan
  override_data {
    target = data.tfe_outputs.spoke["orders"]
    values = { "nonsensitive_values" : { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "spoke-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet", "spoke_virtual_network_name" : "orders-prod-vnet", "spoke_resource_group_name" : "orders", "gateway_transit_enabled" : false, "naming_context" : { "region" : "centralus", "environment" : "prod", "domain" : "internal-apps", "appcode" : "orders" }, "key_vault_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "private_dns_zones" : { "key_vault" : { "name" : "privatelink.vaultcore.azure.net", "resource_group_name" : "dns", "registration_enabled" : false, "link_to_spoke_enabled" : true } } }, "spoke" : { "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "prod" } } } }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "rejects_contract_auto_registration" {
  command = plan
  override_data {
    target = data.tfe_outputs.spoke["orders"]
    values = { "nonsensitive_values" : { "attachment_contract" : { "contract_version" : "2.0.0", "owner" : "central-attachment-workspace", "hub_virtual_network_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet", "spoke_virtual_network_id" : "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-prod-vnet", "spoke_virtual_network_name" : "orders-prod-vnet", "spoke_resource_group_name" : "orders", "gateway_transit_enabled" : false, "naming_context" : { "region" : "centralus", "environment" : "prod", "domain" : "internal-apps", "appcode" : "orders" }, "key_vault_private_dns_zone_id" : "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net", "private_dns_zones" : { "key_vault" : { "name" : "privatelink.vaultcore.azure.net", "resource_group_name" : "dns", "registration_enabled" : true } } }, "spoke" : { "context" : { "tenant_id" : "cccccccc-cccc-cccc-cccc-cccccccccccc", "subscription_id" : "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "environment" : "prod" } } } }
  }
  expect_failures = [terraform_data.producer_contract]
}
