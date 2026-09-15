mock_provider "azurerm" {}

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  location        = "centralus"
  environment     = "prod"
  platform_tags = {
    application         = "conn"
    business_owner      = "cloud"
    source_repo         = "ado://x"
    terraform_workspace = "platform-connectivity"
    recovery_tier       = "standard"
    cost_center         = "CC-0"
    data_classification = "confidential"
    compliance_boundary = "enterprise"
  }
  resource_group = { name = "rg-conn" }
  hub_vnet = {
    name          = "vnet-hub"
    address_space = ["10.0.0.0/16"]
    subnets = {
      private_endpoints     = { address_prefixes = ["10.0.3.0/24"], route_table_key = "to_firewall" }
      cloudflare_connectors = { address_prefixes = ["10.0.2.0/26"], route_table_key = "to_firewall", nsg_key = "connectors" }
      GatewaySubnet         = { address_prefixes = ["10.0.0.0/27"] }
    }
  }
  network_security_groups = { connectors = { name = "nsg-connectors", rules = {} } }
  route_tables = {
    to_firewall = {
      name                          = "rt-to-firewall"
      bgp_route_propagation_enabled = false
      routes                        = { d = { name = "d", address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.0.1.4" } }
    }
  }
  privatelink_zone_catalogue = ["blob", "keyvault", "monitor"]
}

run "subnet_associations_derived" {
  command = plan

  assert {
    condition     = length(local.effective_route_table_associations) == 2
    error_message = "route-table associations not derived from subnet.route_table_key"
  }
  assert {
    condition     = length(local.effective_nsg_associations) == 1
    error_message = "nsg association not derived from subnet.nsg_key"
  }
}

run "privatelink_catalogue_expands" {
  command = plan

  # blob(1) + keyvault(1) + monitor(5 sub-zones, one is blob = dedup) => 6 unique
  assert {
    condition     = length(local.privatelink_zones) == 6
    error_message = "privatelink catalogue did not expand/dedupe as expected"
  }
  assert {
    condition     = contains([for z in values(local.privatelink_zones) : z.name], "privatelink.vaultcore.azure.net")
    error_message = "keyvault privatelink zone missing"
  }
}

run "existing_zone_rejected_without_resource_group" {
  command = plan
  variables {
    private_dns_zones = {
      blob_core_windows_net = { name = "privatelink.blob.core.windows.net", existing = true }
    }
  }
  expect_failures = [var.private_dns_zones]
}

run "existing_zone_is_linked_not_created" {
  command = plan
  variables {
    privatelink_zone_catalogue = ["blob", "keyvault"]
    # Override the catalogue's "blob" entry (same key the catalogue generates:
    # replace(replace(name, "privatelink.", ""), ".", "_")) to point at a zone
    # that already exists elsewhere - var.private_dns_zones wins on key
    # collision with the catalogue.
    private_dns_zones = {
      blob_core_windows_net = {
        name                = "privatelink.blob.core.windows.net"
        existing            = true
        resource_group_name = "rg-shared-dns-existing"
      }
    }
  }
  assert {
    # existing zone is NOT in the create set...
    condition     = !contains(keys(local.private_dns_zones_to_create), "blob_core_windows_net")
    error_message = "an existing zone should not be queued for creation"
  }
  assert {
    # ...but IS in the existing set, still headed for a hub vnet link...
    condition     = contains(keys(local.private_dns_zones_existing), "blob_core_windows_net")
    error_message = "an existing zone should still be recorded for linking"
  }
  assert {
    # ...and the non-existing catalogue entry (keyvault) still gets created as before.
    condition     = contains(keys(local.private_dns_zones_to_create), "vaultcore_azure_net")
    error_message = "a normal (non-existing) catalogue zone should still be created"
  }
}
