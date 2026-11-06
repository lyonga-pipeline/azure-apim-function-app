# Existing v2 producer: no context output, no producer edit, all contracts active.
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
      environment             = "dev"
      address_space           = ["10.20.0.0/24"]
      producer                = { organization = "Compeer-Financial-Services", workspace = "workload-orders-dev", contract_version = "2.0.0" }
      producer_context_source = "contract-and-azure"
      naming_context          = { region = "centralus", environment = "dev", domain = "internal-apps", appcode = "orders" }
      approval_reference      = "NET-123"
      ipam_reference          = "IPAM-orders"
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
    contract_version           = "1.0.0"
    spoke_virtual_network_id   = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-dev-vnet"
    spoke_virtual_network_name = "orders-dev-vnet"
    spoke_resource_group_name  = "orders"
    subnet_ids                 = {}
    attachment_contract = {
      contract_version           = "2.0.0"
      owner                      = "central-attachment-workspace"
      hub_virtual_network_id     = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet"
      spoke_virtual_network_id   = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-dev-vnet"
      spoke_virtual_network_name = "orders-dev-vnet"
      spoke_resource_group_name  = "orders"
      gateway_transit_enabled    = false
      naming_context             = { region = "centralus", environment = "dev", domain = "internal-apps", appcode = "orders" }
      private_dns_zones          = {}
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
override_data {
  target = data.azapi_resource.hub_subscription[0]
  values = { output = { tenantId = "cccccccc-cccc-cccc-cccc-cccccccccccc", subscriptionId = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" } }
}
override_data {
  target = data.azapi_resource.spoke_subscription["orders"]
  values = { output = { tenantId = "cccccccc-cccc-cccc-cccc-cccccccccccc", subscriptionId = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb" } }
}

run "v2_without_context_validates_on_first_plan" {
  command = plan
  assert {
    condition = (
      local.workspace_contexts.orders == null && alltrue(values(local.producer_checks.orders)) &&
      data.azapi_resource.spoke_subscription["orders"].resource_id == "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb" &&
      data.azapi_resource.hub_subscription[0].resource_id == "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" &&
      azapi_resource.hub_to_spoke["orders"].body.properties.remoteVirtualNetwork.id == local.spoke_virtual_network_ids.orders &&
      azapi_resource.spoke_to_hub["orders"].body.properties.remoteVirtualNetwork.id == local.hub_virtual_network_id
    )
    error_message = "Existing six-output producers must validate via their v2 contract and live subscription metadata during the first plan."
  }
}
run "v2_without_context_preserves_both_resource_addresses" {
  command = apply
  assert {
    condition     = length(azapi_resource.hub_to_spoke) == 1 && length(azapi_resource.spoke_to_hub) == 1 && length(azapi_resource.dns_link) == 0 && output.attachments.orders.environment == "dev"
    error_message = "The compatibility source must not change resource identity or introduce DNS links."
  }
}
run "sensitive_comparison_keeps_validation_active" {
  command = plan
  variables { tenant_id = sensitive("cccccccc-cccc-cccc-cccc-cccccccccccc") }
  assert {
    condition     = issensitive(local.producer_checks.orders.tenant) && alltrue(values(local.producer_checks.orders))
    error_message = "Sensitive comparison results must remain protected without changing validation."
  }
}
run "sensitive_tenant_mismatch_still_fails" {
  command = plan
  variables { tenant_id = sensitive("cccccccc-cccc-cccc-cccc-cccccccccccc") }
  override_data {
    target = data.azapi_resource.spoke_subscription["orders"]
    values = { output = { tenantId = "dddddddd-dddd-dddd-dddd-dddddddddddd", subscriptionId = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb" } }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "wrong_spoke_tenant_fails" {
  command = plan
  override_data {
    target = data.azapi_resource.spoke_subscription["orders"]
    values = { output = { tenantId = "dddddddd-dddd-dddd-dddd-dddddddddddd", subscriptionId = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb" } }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "wrong_spoke_subscription_fails" {
  command = plan
  override_data {
    target = data.azapi_resource.spoke_subscription["orders"]
    values = { output = { tenantId = "cccccccc-cccc-cccc-cccc-cccccccccccc", subscriptionId = "dddddddd-dddd-dddd-dddd-dddddddddddd" } }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "missing_subscription_metadata_fails_closed" {
  command = plan
  override_data {
    target = data.azapi_resource.spoke_subscription["orders"]
    values = { output = {} }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "wrong_hub_tenant_fails" {
  command = plan
  override_data {
    target = data.azapi_resource.hub_subscription[0]
    values = { output = { tenantId = "dddddddd-dddd-dddd-dddd-dddddddddddd", subscriptionId = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" } }
  }
  expect_failures = [terraform_data.inventory_contract]
}
run "wrong_hub_subscription_fails" {
  command = plan
  override_data {
    target = data.azapi_resource.hub_subscription[0]
    values = { output = { tenantId = "cccccccc-cccc-cccc-cccc-cccccccccccc", subscriptionId = "dddddddd-dddd-dddd-dddd-dddddddddddd" } }
  }
  expect_failures = [terraform_data.inventory_contract]
}
run "inventory_appcode_cannot_override_producer_naming" {
  command = plan
  variables {
    attachments = { orders = merge(var.attachments.orders, {
      naming_context = { region = "centralus", environment = "dev", domain = "internal-apps", appcode = "wrong" }
    }) }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "inventory_environment_cannot_replace_producer_environment" {
  command = plan
  variables {
    allowed_environments = ["dev", "test"]
    attachments = { orders = merge(var.attachments.orders, {
      environment    = "test"
      naming_context = { region = "centralus", environment = "test", domain = "internal-apps", appcode = "orders" }
    }) }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "workspace_mode_still_requires_context" {
  command = plan
  variables { attachments = { orders = merge(var.attachments.orders, { producer_context_source = "workspace" }) } }
  expect_failures = [terraform_data.producer_contract]
  assert {
    condition     = length(data.azapi_resource.spoke_subscription) == 0 && length(data.azapi_resource.hub_subscription) == 0
    error_message = "Default workspace mode must not acquire subscription metadata permissions or bypass context."
  }
}
run "invalid_mode_is_rejected" {
  command = plan
  variables { attachments = { orders = merge(var.attachments.orders, { producer_context_source = "skip" }) } }
  expect_failures = [var.attachments]
}
run "generic_v3_cannot_use_v2_adapter" {
  command = plan
  variables {
    attachments = { orders = merge(var.attachments.orders, {
      producer       = { organization = "Compeer-Financial-Services", workspace = "workload-orders-dev", contract_version = "3.0.0" }
      naming_context = null
    }) }
  }
  expect_failures = [var.attachments]
}
run "conflicting_published_context_is_not_ignored" {
  command = plan
  override_data {
    target = data.tfe_outputs.spoke["orders"]
    values = { nonsensitive_values = {
      context = { tenant_id = "dddddddd-dddd-dddd-dddd-dddddddddddd", subscription_id = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", environment = "dev" }
      attachment_contract = {
        contract_version           = "2.0.0"
        owner                      = "central-attachment-workspace"
        hub_virtual_network_id     = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/shared-hub-vnet"
        spoke_virtual_network_id   = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders/providers/Microsoft.Network/virtualNetworks/orders-dev-vnet"
        spoke_virtual_network_name = "orders-dev-vnet"
        spoke_resource_group_name  = "orders"
        gateway_transit_enabled    = false
        naming_context             = { region = "centralus", environment = "dev", domain = "internal-apps", appcode = "orders" }
        private_dns_zones          = {}
      }
    } }
  }
  expect_failures = [terraform_data.producer_contract]
}
run "empty_inventory_adds_no_subscription_reads" {
  command = plan
  variables { attachments = {} }
  assert {
    condition     = length(data.azapi_resource.spoke_subscription) == 0 && length(data.azapi_resource.hub_subscription) == 0 && output.attachments == {}
    error_message = "The adapter must stay inert with no attachments."
  }
}
