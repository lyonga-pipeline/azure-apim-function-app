# These tests omit both inventory VNet IDs. Provider mocks never contact Azure/HCP.
mock_provider "azapi" {
  mock_data "azapi_client_config" { defaults = { tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" } }
  mock_resource "azapi_resource" { defaults = { output = { properties = { peeringState = "Connected", provisioningState = "Succeeded" } } } }
}
mock_provider "tfe" {}

variables {
  tenant_id   = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  environment = "dev"
  hub = {
    organization  = "Compeer-Financial-Services"
    workspace     = "platform-connectivity"
    address_space = ["10.0.0.0/16"]
  }
  attachments = {
    orders = {
      environment          = "dev"
      address_space        = ["10.20.0.0/24"]
      producer             = { organization = "Compeer-Financial-Services", workspace = "workload-orders-dev", contract_version = "2.0.0" }
      naming_context       = { region = "centralus", environment = "dev", domain = "internal-apps", appcode = "orders" }
      approval_reference   = "NET-123"
      ipam_reference       = "IPAM-orders"
      private_dns_zone_ids = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
    }
  }
}

override_data {
  target = data.tfe_outputs.hub[0]
  values = { nonsensitive_values = {
    contract_version                  = "0.1.0"
    hub_virtual_network_id            = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet"
    hub_virtual_network_address_space = ["10.0.0.0/16"]
  } }
}
override_data {
  target = data.tfe_outputs.spoke["orders"]
  values = { nonsensitive_values = {
    spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-dev-vnet"
    context = {
      tenant_id       = "cccccccc-cccc-cccc-cccc-cccccccccccc"
      subscription_id = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
      environment     = "dev"
    }
    attachment_contract = {
      contract_version              = "2.0.0"
      owner                         = "central-attachment-workspace"
      hub_virtual_network_id        = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet"
      spoke_virtual_network_id      = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-dev-vnet"
      spoke_virtual_network_name    = "orders-dev-vnet"
      spoke_resource_group_name     = "orders"
      gateway_transit_enabled       = false
      naming_context                = { region = "centralus", environment = "dev", domain = "internal-apps", appcode = "orders" }
      key_vault_private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      private_dns_zones = { key_vault = {
        name                  = "privatelink.vaultcore.azure.net"
        resource_group_name   = "dns"
        registration_enabled  = false
        link_to_spoke_enabled = true
      } }
    }
  } }
}
override_data {
  target = data.azapi_resource.hub[0]
  values = { output = { properties = { addressSpace = { addressPrefixes = ["10.0.0.0/16"] } } } }
}
override_data {
  target = data.azapi_resource.spoke["orders"]
  values = { output = { properties = { addressSpace = { addressPrefixes = ["10.20.0.0/24"] } } } }
}

run "workspace_ids_are_known_and_cross_checked_during_plan" {
  command = plan
  assert {
    condition = (
      var.hub.virtual_network_id == null && var.attachments.orders.spoke_virtual_network_id == null &&
      data.azapi_resource.hub[0].resource_id == local.hub_virtual_network_id &&
      data.azapi_resource.spoke["orders"].resource_id == local.spoke_virtual_network_ids.orders &&
      azapi_resource.hub_to_spoke["orders"].parent_id == local.hub_virtual_network_id &&
      azapi_resource.hub_to_spoke["orders"].body.properties.remoteVirtualNetwork.id == local.spoke_virtual_network_ids.orders &&
      azapi_resource.spoke_to_hub["orders"].parent_id == local.spoke_virtual_network_ids.orders &&
      azapi_resource.spoke_to_hub["orders"].body.properties.remoteVirtualNetwork.id == local.hub_virtual_network_id &&
      azapi_resource.dns_link["orders/key_vault"].body.properties.virtualNetwork.id == local.spoke_virtual_network_ids.orders &&
      alltrue(values(local.producer_checks.orders))
    )
    error_message = "Producer IDs must resolve during plan for both halves, DNS links and all producer checks, without inventory ID literals."
  }
}
run "workspace_ids_preserve_addresses_names_locks_and_outputs" {
  command = apply
  assert {
    condition = (
      length(azapi_resource.hub_to_spoke) == 1 && length(azapi_resource.spoke_to_hub) == 1 &&
      output.attachments.orders.hub_virtual_network_id == local.hub_virtual_network_id &&
      output.attachments.orders.spoke_virtual_network_id == local.spoke_virtual_network_ids.orders &&
      azapi_resource.hub_to_spoke["orders"].name == "shared-hub-vnet-to-orders-dev-vnet" &&
      azapi_resource.spoke_to_hub["orders"].name == "orders-dev-vnet-to-shared-hub-vnet" &&
      azapi_resource.hub_to_spoke["orders"].locks == tolist([lower(local.hub_virtual_network_id)])
    )
    error_message = "Resolving inputs must not change stable attachment addresses, naming, locks or the public output schema."
  }
}
run "missing_hub_output_fails_during_plan" {
  command = plan
  override_data {
    target = data.tfe_outputs.hub[0]
    values = { nonsensitive_values = {} }
  }
  expect_failures = [data.azapi_resource.hub, terraform_data.inventory_contract]
}
run "missing_spoke_outputs_fail_during_plan" {
  command = plan
  override_data {
    target = data.tfe_outputs.spoke["orders"]
    values = { nonsensitive_values = {} }
  }
  expect_failures = [data.azapi_resource.spoke, terraform_data.inventory_contract]
}
run "malformed_spoke_output_fails_during_plan" {
  command = plan
  override_data {
    target = data.tfe_outputs.spoke["orders"]
    values = { nonsensitive_values = { spoke_virtual_network_id = "not-a-vnet-arm-id" } }
  }
  expect_failures = [data.azapi_resource.spoke]
}
run "public_id_alone_does_not_replace_the_attachment_contract" {
  command = plan
  override_data {
    target = data.tfe_outputs.spoke["orders"]
    values = { nonsensitive_values = {
      spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-dev-vnet"
    } }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "explicit_hub_pin_still_rejects_producer_changes" {
  command = plan
  variables {
    hub = {
      organization       = "Compeer-Financial-Services"
      workspace          = "platform-connectivity"
      address_space      = ["10.0.0.0/16"]
      virtual_network_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/different-hub-vnet"
    }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "empty_inventory_needs_no_workspace_ids_or_reads" {
  command = plan
  variables { attachments = {} }
  assert {
    condition     = length(data.tfe_outputs.hub) == 0 && length(data.azapi_resource.hub) == 0 && output.attachments == {}
    error_message = "Optional IDs must not introduce producer reads into an empty attachment state."
  }
}
run "explicit_spoke_pin_still_rejects_producer_changes" {
  command = plan
  variables {
    attachments = {
      orders = {
        spoke_virtual_network_id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/different-orders-dev-vnet"
        environment              = "dev"
        address_space            = ["10.20.0.0/24"]
        producer                 = { organization = "Compeer-Financial-Services", workspace = "workload-orders-dev", contract_version = "2.0.0" }
        naming_context           = { region = "centralus", environment = "dev", domain = "internal-apps", appcode = "orders" }
        approval_reference       = "NET-123"
        ipam_reference           = "IPAM-orders"
        private_dns_zone_ids     = { key_vault = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
      }
    }
  }
  expect_failures = [terraform_data.producer_contract]
}
