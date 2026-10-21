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
  mock_resource "azurerm_virtual_network" {
    defaults = { id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-cus-prod-network-rg/providers/Microsoft.Network/virtualNetworks/orders-cus-prod-spoke-vnet" }
  }
  mock_resource "azurerm_subnet" {
    defaults = { id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-cus-prod-network-rg/providers/Microsoft.Network/virtualNetworks/orders-cus-prod-spoke-vnet/subnets/fixture" }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = { id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-cus-prod-network-rg/providers/Microsoft.Network/networkSecurityGroups/fixture" }
  }
  mock_resource "azurerm_route_table" {
    defaults = { id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-cus-prod-network-rg/providers/Microsoft.Network/routeTables/fixture" }
  }
  mock_resource "azurerm_key_vault" {
    defaults = { id = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-cus-prod-security-rg/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault" }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = { principal_id = "dddddddd-dddd-dddd-dddd-dddddddddddd" }
  }
}
mock_provider "azurerm" {
  alias = "dns"
  mock_data "azurerm_client_config" {
    defaults = { subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" }
  }
}
mock_provider "tfe" {
  mock_data "tfe_outputs" {
    defaults = {
      nonsensitive_values = {
        hub_virtual_network_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
      }
      values = { attachment_contract = "NEVER_READ_SENSITIVE_OUTPUTS" }
    }
  }
}

variables {
  use_tfe_outputs               = false
  use_spoke_attachment_contract = true
  hub_subscription_id           = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  spoke_subscription_id         = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
}

run "spoke_produces_contract_without_a_hub_provider" {
  command = apply
  module { source = "../terraform-azurerm-compeer-spoke-landing-zone" }
  providers = { azurerm = azurerm.spoke, azurerm.dns = azurerm.dns }
  variables {
    tenant_id          = "cccccccc-cccc-cccc-cccc-cccccccccccc"
    subscription_id    = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
    environment        = "prod"
    appcode            = "orders"
    address_space      = ["10.200.0.0/20"]
    egress_next_hop_ip = "10.102.0.4"
    subnets = {
      app               = { address_prefixes = ["10.200.0.0/24"] }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
    workload_tags = {
      application      = "orders", owner = "Applications", source_repo = "ado://Compeer/workloads", created_on = "2026-10-19",
      criticality_tier = "tier-2", data_classification = "confidential", lifecycle_state = "active", cost_center = "CC-0000",
      gl_category      = "cloud-infrastructure", dr_tier = "silver"
    }
    platform = {
      management_contract_version   = "0.1.0", connectivity_contract_version = "0.1.0"
      log_analytics_workspace_id    = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/law"
      hub_virtual_network_id        = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
      hub_address_space             = ["10.102.0.0/21"]
      dns_server_ips                = ["10.102.0.10"]
      key_vault_private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    }
  }
  assert {
    condition     = output.attachment_contract.owner == "central-attachment-workspace" && output.attachment_contract.contract_version == "2.0.0" && !contains(keys(output.attachment_contract), "peering_names")
    error_message = "Spoke provisioning must publish central-owned intent without a hub provider."
  }
}

run "central_owner_consumes_the_actual_spoke_contract" {
  command = apply
  variables { spoke_attachment_contract = run.spoke_produces_contract_without_a_hub_provider.attachment_contract }
  assert {
    condition = (
      output.peerings.hub_to_spoke.name == "hub-to-orders-cus-prod-spoke-vnet" &&
      output.peerings.spoke_to_hub.name == "orders-cus-prod-spoke-vnet-to-hub" &&
      output.peerings.hub_to_spoke.remote_virtual_network_id == run.spoke_produces_contract_without_a_hub_provider.spoke_virtual_network_id &&
      length(output.private_dns_spoke_link_ids) == 1 &&
      local.private_dns_zone_links.key_vault.resource_group_name == "dns" &&
      local.private_dns_zone_links.key_vault.name == "orders-cus-prod-spoke-vnet-link" &&
      local.private_dns_zone_links.key_vault.tags.created_by == "Terraform" &&
      local.private_dns_zone_links.key_vault.virtual_network_id == run.spoke_produces_contract_without_a_hub_provider.spoke_virtual_network_id
    )
    error_message = "A separate attachment state must own both directions and exactly the required DNS links with stable names."
  }
}

run "secretless_contract_connects_without_unused_dns_links" {
  command = apply
  variables {
    spoke_attachment_contract = merge(run.spoke_produces_contract_without_a_hub_provider.attachment_contract, {
      key_vault_private_dns_zone_id = null
      private_dns_zones             = {}
    })
  }
  assert {
    condition     = length(output.private_dns_spoke_link_ids) == 0 && output.peerings.hub_to_spoke.remote_virtual_network_id == run.spoke_produces_contract_without_a_hub_provider.spoke_virtual_network_id
    error_message = "The central state must still create reciprocal peerings without fabricating a vault DNS link for a secretless spoke."
  }
}

run "hcp_reads_only_the_public_attachment_contract" {
  command = apply
  variables {
    use_tfe_outputs  = true
    tfe_organization = "integration-fixture"
  }
  override_data {
    target = data.tfe_outputs.workload_spoke[0]
    values = {
      nonsensitive_values = {
        attachment_contract = {
          contract_version                 = "1.0.0", owner = "central-attachment-workspace", gateway_transit_enabled = false
          hub_virtual_network_id           = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
          spoke_virtual_network_id         = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-cus-prod-network-rg/providers/Microsoft.Network/virtualNetworks/orders-cus-prod-spoke-vnet"
          spoke_virtual_network_name       = "orders-cus-prod-spoke-vnet", spoke_resource_group_name = "orders-cus-prod-network-rg"
          key_vault_private_dns_zone_id    = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
          storage_blob_private_dns_zone_id = null
          peering_names                    = { hub_to_spoke = "hub-to-orders", spoke_to_hub = "orders-to-hub" }
          private_dns_zones = {
            key_vault = {
              name                 = "privatelink.vaultcore.azure.net", resource_group_name = "dns", link_name = "orders-vault",
              registration_enabled = false, link_to_spoke_enabled = true
            }
          }
        }
      }
      values = { attachment_contract = "NEVER_READ_SENSITIVE_OUTPUTS" }
    }
  }
  assert {
    condition = (
      length(output.private_dns_spoke_link_ids) == 1 && length(module.attachment_naming) == 0 &&
      output.peerings.hub_to_spoke.name == "hub-to-orders" && output.peerings.spoke_to_hub.name == "orders-to-hub" &&
      local.private_dns_zone_links.key_vault.name == "orders-vault" &&
      output.peerings.spoke_to_hub.remote_virtual_network_id == run.spoke_produces_contract_without_a_hub_provider.attachment_contract.hub_virtual_network_id
    )
    error_message = "The attachment adapter must read only the public contract, including DNS requirements."
  }
}

run "rejects_competing_spoke_ownership" {
  command = plan
  variables {
    spoke_attachment_contract = merge(run.spoke_produces_contract_without_a_hub_provider.attachment_contract, { owner = "this-blueprint" })
  }
  expect_failures = [terraform_data.resolved_input_validation]
}

run "hcp_v2_contract_is_named_by_the_central_owner" {
  command = apply
  variables {
    use_tfe_outputs  = true
    tfe_organization = "integration-fixture"
  }
  override_data {
    target = data.tfe_outputs.workload_spoke[0]
    values = {
      nonsensitive_values = {
        attachment_contract = {
          contract_version              = "2.0.0", owner = "central-attachment-workspace", gateway_transit_enabled = false
          hub_virtual_network_id        = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
          spoke_virtual_network_id      = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/orders-cus-prod-network-rg/providers/Microsoft.Network/virtualNetworks/orders-cus-prod-spoke-vnet"
          spoke_virtual_network_name    = "orders-cus-prod-spoke-vnet", spoke_resource_group_name = "orders-cus-prod-network-rg"
          key_vault_private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
          naming_context                = { region = "centralus", environment = "prod", domain = "internal-apps", appcode = "orders" }
          private_dns_zones = {
            key_vault = {
              name = "privatelink.vaultcore.azure.net", resource_group_name = "dns", registration_enabled = false, link_to_spoke_enabled = true
            }
          }
        }
      }
      values = { attachment_contract = "NEVER_READ_SENSITIVE_OUTPUTS" }
    }
  }
  assert {
    condition = (
      length(module.attachment_naming) == 1 && output.peerings.hub_to_spoke.name == "hub-to-orders-cus-prod-spoke-vnet" &&
      output.peerings.spoke_to_hub.name == "orders-cus-prod-spoke-vnet-to-hub" &&
      local.private_dns_zone_links.key_vault.name == "orders-cus-prod-spoke-vnet-link"
    )
    error_message = "Public HCP v2 outputs must supply only identity/requirements; the central naming module supplies both peering names and the DNS link name."
  }
}

run "central_owner_can_preserve_existing_custom_names" {
  command = apply
  variables {
    spoke_attachment_contract = run.spoke_produces_contract_without_a_hub_provider.attachment_contract
    peering_names             = { hub_to_spoke = "approved-existing-hub-peer", spoke_to_hub = "approved-existing-spoke-peer" }
    private_dns_link_names    = { key_vault = "approved-existing-vault-link" }
  }
  assert {
    condition = (
      output.peerings.hub_to_spoke.name == "approved-existing-hub-peer" &&
      output.peerings.spoke_to_hub.name == "approved-existing-spoke-peer" &&
      local.private_dns_zone_links.key_vault.name == "approved-existing-vault-link"
    )
    error_message = "Only central-owner inputs may override v2 attachment names to preserve approved Azure identities."
  }
}

run "rejects_v2_contract_without_naming_context" {
  command = plan
  variables {
    spoke_attachment_contract = merge(run.spoke_produces_contract_without_a_hub_provider.attachment_contract, { naming_context = null })
  }
  expect_failures = [terraform_data.resolved_input_validation]
}

run "rejects_v2_spoke_supplied_peering_names" {
  command = plan
  variables {
    spoke_attachment_contract = merge(run.spoke_produces_contract_without_a_hub_provider.attachment_contract, {
      peering_names = { hub_to_spoke = "spoke-selected-hub-name", spoke_to_hub = "spoke-selected-spoke-name" }
    })
  }
  expect_failures = [terraform_data.resolved_input_validation]
}

run "rejects_v2_spoke_supplied_dns_link_names" {
  command = plan
  variables {
    spoke_attachment_contract = merge(run.spoke_produces_contract_without_a_hub_provider.attachment_contract, {
      private_dns_zones = {
        key_vault = {
          name      = "privatelink.vaultcore.azure.net", resource_group_name = "dns", registration_enabled = false
          link_name = "spoke-selected-link"
        }
      }
    })
  }
  expect_failures = [terraform_data.resolved_input_validation]
}

run "rejects_unknown_central_dns_name_override_key" {
  command = plan
  variables {
    spoke_attachment_contract = run.spoke_produces_contract_without_a_hub_provider.attachment_contract
    private_dns_link_names    = { typo_vault_key = "approved-existing-vault-link" }
  }
  expect_failures = [terraform_data.resolved_input_validation]
}

run "rejects_unapproved_contract_version" {
  command = plan
  variables {
    spoke_attachment_contract = merge(run.spoke_produces_contract_without_a_hub_provider.attachment_contract, { contract_version = "99.0.0" })
  }
  expect_failures = [terraform_data.resolved_input_validation]
}

run "rejects_missing_contract_without_legacy_fallback" {
  command         = plan
  expect_failures = [terraform_data.resolved_input_validation]
}

run "rejects_missing_required_dns_link" {
  command = plan
  variables {
    spoke_attachment_contract = merge(run.spoke_produces_contract_without_a_hub_provider.attachment_contract, { private_dns_zones = {} })
  }
  expect_failures = [terraform_data.resolved_input_validation]
}

run "gateway_request_requires_explicit_central_approval" {
  command = plan
  variables {
    spoke_attachment_contract = merge(run.spoke_produces_contract_without_a_hub_provider.attachment_contract, { gateway_transit_enabled = true })
  }
  expect_failures = [terraform_data.resolved_input_validation]
}

run "rejects_dns_subscription_mismatch" {
  command = plan
  variables {
    spoke_attachment_contract = merge(run.spoke_produces_contract_without_a_hub_provider.attachment_contract, {
      key_vault_private_dns_zone_id = "/subscriptions/dddddddd-dddd-dddd-dddd-dddddddddddd/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    })
  }
  expect_failures = [terraform_data.resolved_input_validation]
}

run "rejects_malformed_dns_arm_id" {
  command = plan
  variables {
    spoke_attachment_contract = merge(run.spoke_produces_contract_without_a_hub_provider.attachment_contract, {
      key_vault_private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Storage/accounts/privatelink.vaultcore.azure.net"
    })
  }
  expect_failures = [terraform_data.resolved_input_validation]
}

run "approved_gateway_request_is_applied_as_a_pair" {
  command = plan
  variables {
    spoke_attachment_contract = merge(run.spoke_produces_contract_without_a_hub_provider.attachment_contract, { gateway_transit_enabled = true })
    hub_to_spoke              = { allow_gateway_transit = true }
    spoke_to_hub              = { use_remote_gateways = true }
  }
  assert {
    condition     = output.peerings.hub_to_spoke.allow_gateway_transit && output.peerings.spoke_to_hub.use_remote_gateways
    error_message = "Central approval must match the request on both sides."
  }
}

run "rejects_contract_hub_override" {
  command = plan
  variables {
    spoke_attachment_contract = run.spoke_produces_contract_without_a_hub_provider.attachment_contract
    hub_virtual_network_id    = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/another"
  }
  expect_failures = [terraform_data.resolved_input_validation]
}

run "blob_contract_adds_only_the_required_blob_zone" {
  command = apply
  variables {
    spoke_attachment_contract = merge(run.spoke_produces_contract_without_a_hub_provider.attachment_contract, {
      storage_blob_private_dns_zone_id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
      private_dns_zones = merge(run.spoke_produces_contract_without_a_hub_provider.attachment_contract.private_dns_zones, {
        storage_blob = {
          name                 = "privatelink.blob.core.windows.net", resource_group_name = "dns",
          registration_enabled = false, link_to_spoke_enabled = true
        }
      })
    })
  }
  assert {
    condition     = toset(keys(output.private_dns_spoke_link_ids)) == toset(["key_vault", "storage_blob"])
    error_message = "Required Blob DNS must be linked without legacy default zones for unused services."
  }
}
