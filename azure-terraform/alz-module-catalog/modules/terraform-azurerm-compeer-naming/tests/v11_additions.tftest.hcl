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
