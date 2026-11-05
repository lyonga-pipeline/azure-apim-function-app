mock_provider "azurerm" {}
variables {
  name                = "nsg-app"
  resource_group_name = "rg-net"
  location            = "eastus2"
  security_rules = {
    allow-https-in = {
      name              = "allow-https-in", priority = 100, direction = "Inbound", access = "Allow"
      protocol          = "Tcp", source_address_prefix = "*", destination_port_range = "443", destination_address_prefix = "*"
      source_port_range = "*"
    }
  }
}
run "create" {
  command = apply
  assert {
    condition     = length(azurerm_network_security_group.network_security_group.security_rule) == 1
    error_message = "expected one security rule"
  }
}
run "add_rule_is_additive" {
  command = apply
  variables {
    security_rules = {
      allow-https-in = { name = "allow-https-in", priority = 100, direction = "Inbound", access = "Allow", protocol = "Tcp", source_address_prefix = "*", destination_port_range = "443", destination_address_prefix = "*", source_port_range = "*" }
      deny-all-in    = { name = "deny-all-in", priority = 4000, direction = "Inbound", access = "Deny", protocol = "*", source_address_prefix = "*", destination_port_range = "*", destination_address_prefix = "*", source_port_range = "*" }
    }
  }
  assert {
    condition     = length(azurerm_network_security_group.network_security_group.security_rule) == 2
    error_message = "adding a rule key adds one rule"
  }
}
run "rejects_bad_priority" {
  command = plan
  variables {
    security_rules = { x = { name = "x", priority = 99, direction = "Inbound", access = "Allow", protocol = "Tcp" } }
  }
  expect_failures = [var.security_rules]
}

run "remove_all_inline_rules_is_explicit" {
  command = apply
  variables { security_rules = {} }
  assert {
    condition     = length(azurerm_network_security_group.network_security_group.security_rule) == 0 && output.id == run.create.id
    error_message = "Removing the last configured rule must explicitly clear inline rules without replacing the NSG."
  }
}

run "legacy_list_still_owns_its_rules" {
  command = apply
  variables {
    security_rules = {}
    security_rule = [{
      name                  = "legacy-deny", protocol = "*", source_port_range = "*", destination_port_range = "*",
      source_address_prefix = "*", destination_address_prefix = "*", access = "Deny", priority = 4096, direction = "Inbound"
    }]
  }
  assert {
    condition     = length(azurerm_network_security_group.network_security_group.security_rule) == 1
    error_message = "The legacy rule-list interface must still work with explicit collection ownership."
  }
}
