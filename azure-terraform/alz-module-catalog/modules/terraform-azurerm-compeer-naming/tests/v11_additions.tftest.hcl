# v1.1 additions: subscription_security, resource_group_names (keyed),
# vnet_peering_names, private_dns_link_names. All additive - no existing
# output's value changes as a result of these tests or the code they cover.

run "subscription_security_row" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
  }

  assert {
    condition     = output.subscription_security == "sub-security-prod-cus"
    error_message = "subscription_security should match sub-security-<env>-<region>"
  }
}

run "resource_group_names_platform_scope_includes_component" {
  command = apply

  variables {
    region              = "centralus"
    environment         = "prod"
    scope               = "platform"
    component           = "management"
    resource_group_keys = ["network", "security"]
  }

  assert {
    condition     = output.resource_group_names["network"] == "platform-cus-prod-management-network-rg"
    error_message = "platform-scope keyed RG must include region, env, component and key"
  }
  assert {
    condition     = output.resource_group_names["security"] == "platform-cus-prod-management-security-rg"
    error_message = "platform-scope keyed RG must include region, env, component and key"
  }
}

run "resource_group_names_stay_collision_safe_across_roots" {
  command = apply

  variables {
    region              = "centralus"
    environment         = "prod"
    scope               = "platform"
    component           = "connectivity"
    resource_group_keys = ["network"]
  }

  assert {
    # Same key ("network") as the management-scoped run above must NOT
    # collide - the component token must disambiguate the two roots.
    condition     = output.resource_group_names["network"] == "platform-cus-prod-connectivity-network-rg"
    error_message = "keyed RG names must include component to stay collision-safe across different platform roots"
  }
}

run "resource_group_names_workload_scope_uses_stem" {
  command = apply

  variables {
    region              = "centralus"
    environment         = "prod"
    scope               = "workload"
    domain              = "internal-apps"
    appcode             = "orders"
    resource_group_keys = ["network"]
  }

  assert {
    condition     = output.resource_group_names["network"] == "internal-apps-orders-cus-prod-network-rg"
    error_message = "workload-scope keyed RG must use the existing stem (<domain>-<appcode>-<region>-<env>)"
  }
}

run "vnet_peering_names_one_per_side" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
    vnet_peerings = {
      hub_to_identity = { local_vnet = "platform-cus-prod-hub-vnet", remote_vnet = "platform-cus-prod-identity-vnet" }
      identity_to_hub = { local_vnet = "platform-cus-prod-identity-vnet", remote_vnet = "platform-cus-prod-hub-vnet" }
    }
  }

  assert {
    condition     = output.vnet_peering_names["hub_to_identity"] == "platform-cus-prod-hub-vnet-to-platform-cus-prod-identity-vnet"
    error_message = "vnet_peering_names must follow <local-vnet>-to-<remote-vnet>"
  }
  assert {
    condition     = output.vnet_peering_names["identity_to_hub"] == "platform-cus-prod-identity-vnet-to-platform-cus-prod-hub-vnet"
    error_message = "the reciprocal direction must be a distinct, correctly-ordered name"
  }
}

run "private_dns_link_names" {
  command = apply

  variables {
    region                 = "centralus"
    environment            = "prod"
    private_dns_link_vnets = ["platform-cus-prod-hub-vnet", "app1-cus-prod-spoke-vnet"]
  }

  assert {
    condition     = output.private_dns_link_names["platform-cus-prod-hub-vnet"] == "platform-cus-prod-hub-vnet-link"
    error_message = "private_dns_link_names must follow <vnet-name>-link"
  }
  assert {
    condition     = output.private_dns_link_names["app1-cus-prod-spoke-vnet"] == "app1-cus-prod-spoke-vnet-link"
    error_message = "private_dns_link_names must follow <vnet-name>-link"
  }
}

run "domain_controller_computer_name_fits_15_chars_in_short_region" {
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
    instance    = 1
  }

  assert {
    condition     = output.domain_controller_computer_name == "AZR-CUS-ADS-01"
    error_message = "expected AZR-CUS-ADS-01 for centralus instance 1"
  }
  assert {
    condition     = output.domain_controller_extdc_computer_name == "AZR-CUS-EXD-01"
    error_message = "expected AZR-CUS-EXD-01 for centralus instance 1"
  }
  assert {
    condition     = length(output.domain_controller_computer_name) <= 15 && length(output.domain_controller_extdc_computer_name) <= 15
    error_message = "computer names must fit the 15-char NetBIOS limit"
  }
}

run "domain_controller_computer_name_fits_15_chars_in_worst_case_four_letter_region" {
  # eastus2's short code ("eus2") is 4 chars, the longest in the approved
  # region list - this is the case that would overflow with a 4-char role
  # token like "ADDS" (16 chars). Prove the 3-char role token stays <=15
  # here specifically, not just for centralus.
  command = apply

  variables {
    region      = "eastus2"
    environment = "prod"
    instance    = 99
  }

  assert {
    condition     = output.domain_controller_computer_name == "AZR-EUS2-ADS-99"
    error_message = "expected AZR-EUS2-ADS-99 for eastus2 instance 99"
  }
  assert {
    condition     = length(output.domain_controller_computer_name) == 15
    error_message = "worst-case region + max instance should land exactly at the 15-char ceiling, not over it"
  }
  assert {
    condition     = length(output.domain_controller_extdc_computer_name) == 15
    error_message = "worst-case region + max instance should land exactly at the 15-char ceiling for the external-forest variant too"
  }
}

run "v10_and_prior_outputs_unchanged" {
  # Regression guard: none of the v1.1 additions may alter an existing
  # output's value for identical inputs.
  command = apply

  variables {
    region      = "centralus"
    environment = "prod"
    scope       = "platform"
    component   = "management"
  }

  assert {
    condition     = output.resource_group == "platform-cus-prod-management-rg"
    error_message = "the pre-existing singular resource_group output must be untouched by the new keyed resource_group_names output"
  }
  assert {
    condition     = output.hub_vnet == "platform-cus-prod-hub-vnet" && output.identity_vnet == "platform-cus-prod-identity-vnet"
    error_message = "pre-existing networking outputs must be untouched"
  }
}
