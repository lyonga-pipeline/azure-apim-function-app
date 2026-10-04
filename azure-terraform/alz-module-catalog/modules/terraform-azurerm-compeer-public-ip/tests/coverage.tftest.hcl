mock_provider "azurerm" {}

variables {
  name                = "platform-cus-prod-rs-pip"
  resource_group_name = "rg-connectivity"
  location            = "centralus"
}

run "all_optional_nulls_are_accepted" {
  # Regression guard: the optional null-defaulted inputs (domain_name_label_scope,
  # ddos_protection_mode) used a null-unsafe `|| contains()` validation that
  # crashed every plan with defaults - this module could not create ANY public IP.
  command = plan

  assert {
    condition     = azurerm_public_ip.ip.sku == "Standard" && azurerm_public_ip.ip.allocation_method == "Static"
    error_message = "a public IP with only required inputs must plan cleanly"
  }
}

run "design_doc_route_server_pip_shape" {
  # platform-cus-prod-rs-pip: Standard, Static, zones 1/2/3 (zone redundant).
  command = apply
  variables {
    zones = ["1", "2", "3"]
  }

  assert {
    condition     = length(azurerm_public_ip.ip.zones) == 3
    error_message = "zone-redundant Standard public IP should be accepted"
  }
}

run "outputs_are_wired" {
  command = apply

  assert {
    condition = (
      output.id == azurerm_public_ip.ip.id &&
      output.name == azurerm_public_ip.ip.name &&
      output.resource_group_name == azurerm_public_ip.ip.resource_group_name &&
      output.location == azurerm_public_ip.ip.location &&
      output.ip_address == azurerm_public_ip.ip.ip_address &&
      output.fqdn == azurerm_public_ip.ip.fqdn &&
      output.zones == azurerm_public_ip.ip.zones
    )
    error_message = "every output must echo its corresponding resource attribute"
  }
}

run "rejects_bad_domain_name_label_scope" {
  command = plan
  variables {
    domain_name_label_scope = "Everywhere"
  }
  expect_failures = [var.domain_name_label_scope]
}

run "accepts_valid_domain_name_label_scope" {
  command = plan
  variables {
    domain_name_label       = "platform-cus-prod-rs"
    domain_name_label_scope = "NoReuse"
  }

  assert {
    condition     = azurerm_public_ip.ip.domain_name_label_scope == "NoReuse"
    error_message = "a valid domain_name_label_scope should be accepted"
  }
}

run "rejects_bad_ddos_protection_mode" {
  command = plan
  variables {
    ddos_protection_mode = "Maybe"
  }
  expect_failures = [var.ddos_protection_mode]
}

run "rejects_ddos_plan_without_enabled_mode" {
  command = plan
  variables {
    ddos_protection_plan_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/ddosProtectionPlans/ddos"
  }
  expect_failures = [azurerm_public_ip.ip]
}

run "accepts_ddos_plan_with_enabled_mode" {
  command = plan
  variables {
    ddos_protection_mode    = "Enabled"
    ddos_protection_plan_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/ddosProtectionPlans/ddos"
  }

  assert {
    condition     = azurerm_public_ip.ip.ddos_protection_mode == "Enabled"
    error_message = "a DDoS plan with mode Enabled should be accepted"
  }
}

run "rejects_zones_on_basic_sku" {
  command = plan
  variables {
    sku   = "Basic"
    zones = ["1"]
  }
  expect_failures = [azurerm_public_ip.ip]
}

run "rejects_global_tier_on_basic_sku" {
  command = plan
  variables {
    sku      = "Basic"
    sku_tier = "Global"
  }
  expect_failures = [azurerm_public_ip.ip]
}

run "accepts_basic_sku_with_dynamic_allocation" {
  command = plan
  variables {
    sku               = "Basic"
    allocation_method = "Dynamic"
  }

  assert {
    condition     = azurerm_public_ip.ip.sku == "Basic" && azurerm_public_ip.ip.allocation_method == "Dynamic"
    error_message = "Basic/Dynamic is a valid combination"
  }
}

run "rejects_idle_timeout_below_minimum" {
  command = plan
  variables {
    idle_timeout_in_minutes = 3
  }
  expect_failures = [var.idle_timeout_in_minutes]
}

run "rejects_name_ending_with_hyphen" {
  command = plan
  variables {
    name = "platform-cus-prod-rs-"
  }
  expect_failures = [var.name]
}

run "rejects_name_starting_with_underscore" {
  command = plan
  variables {
    name = "_pip"
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
