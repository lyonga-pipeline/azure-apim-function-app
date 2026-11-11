# Exercise management settings in the deployable root terraform.tfvars directly.
mock_provider "azurerm" {
  mock_data "azurerm_private_dns_zone" {
    defaults = { id = "/subscriptions/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net" }
  }
}
mock_provider "tfe" {}
mock_provider "time" {
  mock_resource "time_static" { defaults = { rfc3339 = "2026-11-11T00:00:00Z" } }
}
variables {
  tenant_id       = "cccccccc-cccc-cccc-cccc-cccccccccccc"
  subscription_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  use_tfe_outputs = false
}
run "compeer_pilot_retains_management_association_and_symmetric_routes" {
  command = plan
  assert {
    condition = (
      var.firewall_routing.management_route_table_key == "mgmt" &&
      local.firewall_route_checks["management.expected_association"] &&
      local.firewall_effective_hub_vnet.subnets["prod-mgmt-subnet"].route_table_key == "mgmt" &&
      length(local.firewall_management_table_keys) == 1 &&
      local.firewall_effective_route_tables.mgmt.bgp_route_propagation_enabled &&
      toset([for route in values(local.firewall_effective_route_tables.mgmt.routes) : route.address_prefix]) == toset(["0.0.0.0/0", "10.102.8.0/27", "10.102.64.0/27"]) &&
      alltrue([for route in values(local.firewall_effective_route_tables.mgmt.routes) : route.next_hop_type == "VirtualAppliance" && route.next_hop_in_ip_address == "10.102.4.42"])
    )
    error_message = "The Compeer pilot must retain the management association/BGP/default and both inspected spoke routes."
  }
}
