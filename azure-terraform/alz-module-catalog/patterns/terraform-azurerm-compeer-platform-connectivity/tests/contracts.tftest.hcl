mock_provider "azurerm" {}

# Exercises terraform_data.palo_alto_route_contract and
# terraform_data.dns_resolution_contract - the preconditions that keep the
# egress-firewall architecture and the DNS mode switch from being
# half-configured (design doc §8.5 default-deny hub firewall; NET-27 DNS
# decision). Neither had dedicated test coverage before this file.

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
      trust     = { address_prefixes = ["10.0.1.0/26"] }
      untrust   = { address_prefixes = ["10.0.1.64/26"] }
      palo_mgmt = { address_prefixes = ["10.0.1.128/28"] }
    }
  }
  route_tables = {
    to_firewall = {
      name                          = "rt-to-firewall"
      bgp_route_propagation_enabled = false
      routes = {
        default = { name = "default", address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.0.1.4" }
      }
    }
  }
  privatelink_zone_catalogue = []
}

run "palo_alto_off_by_default_is_a_noop" {
  command = plan
  assert {
    condition     = terraform_data.palo_alto_route_contract.input.enabled == false
    error_message = "palo alto posture should be disabled by default"
  }
}

run "palo_alto_enabled_requires_declared_ip" {
  command = plan
  variables {
    palo_alto = {
      enabled              = true
      private_ip_addresses = {}
    }
  }
  expect_failures = [terraform_data.palo_alto_route_contract]
}

run "palo_alto_rejects_undeclared_route_next_hop" {
  command = plan
  variables {
    palo_alto = {
      enabled              = true
      private_ip_addresses = { primary = "10.0.1.99" } # does not match the route's 10.0.1.4
      trusted_subnet_key   = "trust"
      untrusted_subnet_key = "untrust"
    }
  }
  expect_failures = [terraform_data.palo_alto_route_contract]
}

run "palo_alto_rejects_missing_subnet_key" {
  command = plan
  variables {
    palo_alto = {
      enabled               = true
      private_ip_addresses  = { primary = "10.0.1.4" }
      trusted_subnet_key    = "trust"
      untrusted_subnet_key  = "untrust"
      management_subnet_key = "does_not_exist"
    }
  }
  expect_failures = [terraform_data.palo_alto_route_contract]
}

run "palo_alto_valid_configuration_passes" {
  command = plan
  variables {
    palo_alto = {
      enabled               = true
      private_ip_addresses  = { primary = "10.0.1.4" }
      trusted_subnet_key    = "trust"
      untrusted_subnet_key  = "untrust"
      management_subnet_key = "palo_mgmt"
    }
  }
  assert {
    condition     = terraform_data.palo_alto_route_contract.input.enabled == true
    error_message = "expected the contract to record the enabled posture"
  }
}

run "dns_resolution_off_by_default_is_a_noop" {
  command = plan
  assert {
    condition     = terraform_data.dns_resolution_contract.input.mode == "dc-forwarders"
    error_message = "dc-forwarders should be the default mode even when disabled"
  }
}

run "dns_resolution_dc_forwarders_requires_server_ips" {
  command = plan
  variables {
    dns_resolution = {
      enabled = true
      mode    = "dc-forwarders"
    }
  }
  expect_failures = [terraform_data.dns_resolution_contract]
}

run "dns_resolution_dc_forwarders_with_ips_passes" {
  command = plan
  variables {
    dns_resolution = {
      enabled        = true
      mode           = "dc-forwarders"
      dns_server_ips = ["10.10.0.4", "10.10.0.5"]
    }
  }
  assert {
    condition     = length(terraform_data.dns_resolution_contract.input.dns_server_ips) == 2
    error_message = "expected the DC forwarder IPs to be recorded"
  }
}

run "dns_resolution_rejects_unknown_mode" {
  command = plan
  variables {
    dns_resolution = {
      enabled = true
      mode    = "made-up-mode"
    }
  }
  expect_failures = [var.dns_resolution]
}

# Regression: private_dns_resolver (the module that would have actually built
# a resolver-based DNS path) was removed - network engineer confirmed this
# environment uses conditional forwarders on the existing domain controllers,
# not Azure DNS Private Resolver. dc-forwarders is the only mode this pattern
# can still fulfil, so private-resolver/hybrid must be rejected, not silently
# accepted as a no-op.
run "dns_resolution_rejects_private_resolver_mode" {
  command = plan
  variables {
    dns_resolution = {
      enabled = true
      mode    = "private-resolver"
    }
  }
  expect_failures = [var.dns_resolution]
}

run "dns_resolution_rejects_hybrid_mode" {
  command = plan
  variables {
    dns_resolution = {
      enabled = true
      mode    = "hybrid"
    }
  }
  expect_failures = [var.dns_resolution]
}
