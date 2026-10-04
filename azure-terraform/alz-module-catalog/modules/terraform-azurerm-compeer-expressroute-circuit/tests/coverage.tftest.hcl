mock_provider "azurerm" {}

variables {
  name                  = "platform-cus-prod-er"
  resource_group_name   = "rg-connectivity"
  location              = "centralus"
  service_provider_name = "Equinix"
  peering_location      = "Chicago Metro"
  bandwidth_in_mbps     = 2000
}

run "design_doc_circuit_is_accepted" {
  # platform-cus-prod-er: Equinix, Chicago Metro, 2 Gbps, Standard SKU,
  # Unlimited billing model.
  command = apply
  variables {
    sku = {
      tier   = "Standard"
      family = "UnlimitedData"
    }
  }

  assert {
    condition = (
      azurerm_express_route_circuit.circuit.bandwidth_in_mbps == 2000 &&
      azurerm_express_route_circuit.circuit.sku[0].tier == "Standard" &&
      azurerm_express_route_circuit.circuit.sku[0].family == "UnlimitedData"
    )
    error_message = "the design-doc circuit shape must be accepted"
  }
}

run "outputs_are_wired" {
  command = apply

  assert {
    condition = (
      output.id == azurerm_express_route_circuit.circuit.id &&
      output.name == azurerm_express_route_circuit.circuit.name &&
      output.service_key == azurerm_express_route_circuit.circuit.service_key &&
      output.service_provider_provisioning_state == azurerm_express_route_circuit.circuit.service_provider_provisioning_state
    )
    error_message = "every output must echo its corresponding resource attribute (service_key stays sensitive)"
  }
}

run "accepts_premium_tier" {
  command = plan
  variables {
    sku = {
      tier   = "Premium"
      family = "UnlimitedData"
    }
  }

  assert {
    condition     = azurerm_express_route_circuit.circuit.sku[0].tier == "Premium"
    error_message = "Premium is a documented tier"
  }
}

run "rejects_invalid_sku_family" {
  command = plan
  variables {
    sku = {
      tier   = "Standard"
      family = "FlatRate"
    }
  }
  expect_failures = [var.sku]
}

run "rejects_non_whole_bandwidth" {
  command = plan
  variables {
    bandwidth_in_mbps = 1000.5
  }
  expect_failures = [var.bandwidth_in_mbps]
}

run "rejects_empty_service_provider_name" {
  command = plan
  variables {
    service_provider_name = " "
  }
  expect_failures = [var.service_provider_name]
}

run "rejects_empty_peering_location" {
  command = plan
  variables {
    peering_location = ""
  }
  expect_failures = [var.peering_location]
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

run "rejects_name_ending_with_hyphen" {
  command = plan
  variables {
    name = "platform-cus-prod-er-"
  }
  expect_failures = [var.name]
}

run "rejects_name_starting_with_underscore" {
  command = plan
  variables {
    name = "_er"
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

run "classic_operations_default_to_disabled" {
  command = plan

  assert {
    condition     = azurerm_express_route_circuit.circuit.allow_classic_operations == false
    error_message = "allow_classic_operations must default to false"
  }
}
