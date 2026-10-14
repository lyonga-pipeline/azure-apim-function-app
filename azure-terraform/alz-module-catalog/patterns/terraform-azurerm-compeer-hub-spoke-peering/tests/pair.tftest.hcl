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
    defaults = { subscription_id = "dddddddd-dddd-dddd-dddd-dddddddddddd", tenant_id = "cccccccc-cccc-cccc-cccc-cccccccccccc" }
  }
}

variables {
  tenant_id                   = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  hub_subscription_id         = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  spoke_subscription_id       = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
  private_dns_subscription_id = "dddddddd-dddd-dddd-dddd-dddddddddddd"
  hub_virtual_network_id      = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub-vnet"
  spoke_virtual_network_id    = "/subscriptions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/resourceGroups/spoke/providers/Microsoft.Network/virtualNetworks/spoke-vnet"
  private_dns_zones           = {}
  peering_name_prefix         = "orders-cus-prod"
  peering_names               = { hub_to_spoke = "hub-vnet-to-spoke-vnet", spoke_to_hub = "spoke-vnet-to-hub-vnet" }
}

run "NET_22_pair_composes_both_sides_without_dns_duplicates" {
  command = apply
  assert {
    condition = (
      output.peerings.hub_to_spoke.remote_virtual_network_id == var.spoke_virtual_network_id &&
      output.peerings.spoke_to_hub.remote_virtual_network_id == var.hub_virtual_network_id &&
      output.peerings.hub_to_spoke.name == var.peering_names.hub_to_spoke &&
      output.peerings.spoke_to_hub.name == var.peering_names.spoke_to_hub &&
      output.peerings.hub_to_spoke.allow_forwarded_traffic && output.peerings.spoke_to_hub.allow_forwarded_traffic &&
      !output.peerings.hub_to_spoke.allow_gateway_transit && !output.peerings.spoke_to_hub.use_remote_gateways &&
      length(output.private_dns_spoke_link_ids) == 0
    )
    error_message = "The reusable NET-22 pattern must own both peerings with approved names/flags and no implicit DNS links when the parent owns them."
  }
}

run "paired_gateway_transit_is_supported" {
  command = plan
  variables {
    hub_to_spoke = { allow_gateway_transit = true }
    spoke_to_hub = { use_remote_gateways = true }
  }
  assert {
    condition     = output.peerings.hub_to_spoke.allow_gateway_transit && output.peerings.spoke_to_hub.use_remote_gateways
    error_message = "Gateway transit must be paired after external gateway/Route Server readiness."
  }
}

run "rejects_unpaired_gateway_transit" {
  command = plan
  variables { spoke_to_hub = { use_remote_gateways = true } }
  expect_failures = [terraform_data.contract]
}

run "rejects_reverse_gateway_ownership" {
  command = plan
  variables { hub_to_spoke = { use_remote_gateways = true } }
  expect_failures = [terraform_data.contract]
}

run "rejects_wrong_subscription" {
  command = plan
  variables { hub_subscription_id = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb" }
  expect_failures = [terraform_data.contract]
}

run "rejects_malformed_vnet_id" {
  command = plan
  variables { spoke_virtual_network_id = "not-a-vnet-id" }
  expect_failures = [terraform_data.contract]
}

run "DNS_may_live_outside_the_hub_subscription" {
  command = apply
  variables {
    private_dns_zones = { vault = { name = "privatelink.vaultcore.azure.net", resource_group_name = "existing-central-dns" } }
  }
  assert {
    condition = (module.private_dns_spoke_links.links.vault.resource_group_name == "existing-central-dns" &&
      module.private_dns_spoke_links.links.vault.virtual_network_id == var.spoke_virtual_network_id &&
    !module.private_dns_spoke_links.links.vault.registration_enabled)
    error_message = "DNS links must use the approved existing zone, its RG and the independently scoped DNS provider."
  }
}

run "rejects_wrong_dns_provider_subscription" {
  command = plan
  variables {
    private_dns_subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    private_dns_zones           = { vault = { name = "privatelink.vaultcore.azure.net", resource_group_name = "existing-central-dns" } }
  }
  expect_failures = [terraform_data.contract]
}

run "rejects_vm_autoregistration_in_private_link_zone" {
  command = plan
  variables { private_dns_zones = { vault = { name = "privatelink.vaultcore.azure.net", resource_group_name = "existing-central-dns", registration_enabled = true } } }
  expect_failures = [terraform_data.contract]
}


run "legacy_names_remain_unchanged_without_explicit_override" {
  command = plan
  variables { peering_names = {} }
  assert {
    condition     = output.peerings.hub_to_spoke.name == "peer-orders-cus-prod-hub-to-spoke" && output.peerings.spoke_to_hub.name == "peer-orders-cus-prod-spoke-to-hub"
    error_message = "Existing callers retain their stable Azure peering names and state addresses."
  }
}
