mock_provider "azurerm" {}

variables {
  name                       = "platform-cus-prod-ergw-connection"
  resource_group_name        = "rg-connectivity"
  location                   = "centralus"
  virtual_network_gateway_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworkGateways/platform-cus-prod-ergw"
  express_route_circuit_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/expressRouteCircuits/platform-cus-prod-er"
}

# --- ExpressRoute path -------------------------------------------------------

run "expressroute_connection_without_shared_key_plans_cleanly" {
  # Regression guard: the IPsec shared_key precondition called trimspace(null)
  # for ExpressRoute connections, so no ExpressRoute connection could ever plan.
  command = plan

  assert {
    condition     = azurerm_virtual_network_gateway_connection.connection.type == "ExpressRoute"
    error_message = "an ExpressRoute connection with no shared_key must plan cleanly"
  }
}

run "expressroute_rejects_a_local_network_gateway" {
  command = plan
  variables {
    local_network_gateway_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/localNetworkGateways/onprem"
  }
  expect_failures = [azurerm_virtual_network_gateway_connection.connection]
}

run "expressroute_requires_a_circuit" {
  command = plan
  variables {
    express_route_circuit_id = null
  }
  expect_failures = [azurerm_virtual_network_gateway_connection.connection]
}

run "outputs_are_wired" {
  command = apply

  assert {
    condition = (
      output.id == azurerm_virtual_network_gateway_connection.connection.id &&
      output.name == azurerm_virtual_network_gateway_connection.connection.name &&
      output.type == azurerm_virtual_network_gateway_connection.connection.type &&
      output.resource_group_name == azurerm_virtual_network_gateway_connection.connection.resource_group_name &&
      output.location == azurerm_virtual_network_gateway_connection.connection.location
    )
    error_message = "every output must echo its corresponding resource attribute"
  }
}

# --- IPsec path (the design doc's backup VPN) --------------------------------

run "design_doc_ipsec_connection_is_accepted" {
  # platform-cus-prod-vpn-connection: S2S IPsec, IKEv2, DPD 45s, policy-based
  # selectors disabled, ECP384 / GCMAES256 / SHA256 / GCMAES256 / PFS None.
  command = plan
  variables {
    name                               = "platform-cus-prod-vpn-connection"
    type                               = "IPsec"
    express_route_circuit_id           = null
    local_network_gateway_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/localNetworkGateways/platform-cus-prod-lng"
    shared_key                         = "placeholder-not-a-real-key"
    connection_protocol                = "IKEv2"
    connection_mode                    = "Default"
    dpd_timeout_seconds                = 45
    use_policy_based_traffic_selectors = false
    bgp_enabled                        = true
    ipsec_policy = {
      dh_group         = "ECP384"
      ike_encryption   = "GCMAES256"
      ike_integrity    = "SHA256"
      ipsec_encryption = "GCMAES256"
      ipsec_integrity  = "GCMAES256"
      pfs_group        = "None"
    }
  }

  assert {
    condition     = azurerm_virtual_network_gateway_connection.connection.type == "IPsec"
    error_message = "the design-doc IPsec/IKE policy must be accepted"
  }
}

run "bgp_enabled_preferred_over_deprecated_enable_bgp" {
  command = plan
  variables {
    bgp_enabled = false
    enable_bgp  = true
  }
  assert {
    condition     = azurerm_virtual_network_gateway_connection.connection.bgp_enabled == false
    error_message = "bgp_enabled should override deprecated enable_bgp"
  }
}

run "rejects_bad_connection_mode" {
  command = plan
  variables {
    connection_mode = "Initiator"
  }
  expect_failures = [var.connection_mode]
}

run "rejects_bad_connection_protocol" {
  command = plan
  variables {
    connection_protocol = "IKEv3"
  }
  expect_failures = [var.connection_protocol]
}

run "rejects_bad_dh_group" {
  command = plan
  variables {
    ipsec_policy = {
      dh_group         = "ECP521"
      ike_encryption   = "GCMAES256"
      ike_integrity    = "SHA256"
      ipsec_encryption = "GCMAES256"
      ipsec_integrity  = "GCMAES256"
      pfs_group        = "None"
    }
  }
  expect_failures = [var.ipsec_policy]
}

run "rejects_bad_ike_encryption" {
  command = plan
  variables {
    ipsec_policy = {
      dh_group         = "ECP384"
      ike_encryption   = "GCMAES192" # valid for IPsec encryption, not IKE encryption
      ike_integrity    = "SHA256"
      ipsec_encryption = "GCMAES256"
      ipsec_integrity  = "GCMAES256"
      pfs_group        = "None"
    }
  }
  expect_failures = [var.ipsec_policy]
}

run "rejects_bad_ike_integrity" {
  command = plan
  variables {
    ipsec_policy = {
      dh_group         = "ECP384"
      ike_encryption   = "GCMAES256"
      ike_integrity    = "SHA512"
      ipsec_encryption = "GCMAES256"
      ipsec_integrity  = "GCMAES256"
      pfs_group        = "None"
    }
  }
  expect_failures = [var.ipsec_policy]
}

run "rejects_bad_ipsec_encryption" {
  command = plan
  variables {
    ipsec_policy = {
      dh_group         = "ECP384"
      ike_encryption   = "GCMAES256"
      ike_integrity    = "SHA256"
      ipsec_encryption = "CHACHA20"
      ipsec_integrity  = "GCMAES256"
      pfs_group        = "None"
    }
  }
  expect_failures = [var.ipsec_policy]
}

run "rejects_bad_ipsec_integrity" {
  command = plan
  variables {
    ipsec_policy = {
      dh_group         = "ECP384"
      ike_encryption   = "GCMAES256"
      ike_integrity    = "SHA256"
      ipsec_encryption = "GCMAES256"
      ipsec_integrity  = "SHA384" # valid for IKE integrity, not IPsec integrity
      pfs_group        = "None"
    }
  }
  expect_failures = [var.ipsec_policy]
}

run "rejects_bad_pfs_group" {
  command = plan
  variables {
    ipsec_policy = {
      dh_group         = "ECP384"
      ike_encryption   = "GCMAES256"
      ike_integrity    = "SHA256"
      ipsec_encryption = "GCMAES256"
      ipsec_integrity  = "GCMAES256"
      pfs_group        = "PFS3"
    }
  }
  expect_failures = [var.ipsec_policy]
}

run "rejects_sa_datasize_below_minimum" {
  command = plan
  variables {
    ipsec_policy = {
      dh_group         = "ECP384"
      ike_encryption   = "GCMAES256"
      ike_integrity    = "SHA256"
      ipsec_encryption = "GCMAES256"
      ipsec_integrity  = "GCMAES256"
      pfs_group        = "None"
      sa_datasize      = 1023
    }
  }
  expect_failures = [var.ipsec_policy]
}

run "rejects_sa_lifetime_below_minimum" {
  command = plan
  variables {
    ipsec_policy = {
      dh_group         = "ECP384"
      ike_encryption   = "GCMAES256"
      ike_integrity    = "SHA256"
      ipsec_encryption = "GCMAES256"
      ipsec_integrity  = "GCMAES256"
      pfs_group        = "None"
      sa_lifetime      = 299
    }
  }
  expect_failures = [var.ipsec_policy]
}

# --- naming / required strings ----------------------------------------------

run "rejects_name_ending_with_hyphen" {
  command = plan
  variables {
    name = "platform-cus-prod-ergw-"
  }
  expect_failures = [var.name]
}

run "rejects_name_over_80_chars" {
  command = plan
  variables {
    name = join("", [for i in range(81) : "a"])
  }
  expect_failures = [var.name]
}

run "rejects_empty_resource_group_name" {
  command = plan
  variables {
    resource_group_name = ""
  }
  expect_failures = [var.resource_group_name]
}

run "rejects_blank_location" {
  command = plan
  variables {
    location = " "
  }
  expect_failures = [var.location]
}
