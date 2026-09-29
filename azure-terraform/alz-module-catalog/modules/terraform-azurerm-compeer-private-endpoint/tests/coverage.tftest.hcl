mock_provider "azurerm" {}

variables {
  name                = "pep-kv-platform"
  resource_group_name = "rg-platform"
  location            = "centralus"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-hub/subnets/private_endpoints"
  private_service_connections = [{
    name                           = "pep-kv-platform-psc"
    is_manual_connection           = false
    private_connection_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-platform/providers/Microsoft.KeyVault/vaults/kv-platform"
    subresource_names              = ["vault"]
  }]
}

run "outputs_are_wired" {
  command = apply

  assert {
    condition     = output.id == azurerm_private_endpoint.private_endpoint.id && output.private_endpoint_id == azurerm_private_endpoint.private_endpoint.id
    error_message = "id/private_endpoint_id outputs must echo the resource id"
  }
  assert {
    condition     = output.name == "pep-kv-platform" && output.private_endpoint_name == "pep-kv-platform"
    error_message = "name/private_endpoint_name outputs must echo the resource name"
  }
  assert {
    condition     = output.subnet_id == var.subnet_id
    error_message = "subnet_id output must echo the configured subnet"
  }
}

run "private_dns_zone_group_empty_by_default" {
  command = plan

  assert {
    condition     = length(local.private_dns_zone_groups) == 0
    error_message = "no private_dns_zone_group entries should be rendered when the variable is left at its empty default"
  }
}

run "rejects_more_than_one_private_dns_zone_group" {
  command = plan
  variables {
    private_dns_zone_group = [
      { name = "zone1", private_dns_zone_ids = ["/subscriptions/x/providers/Microsoft.Network/privateDnsZones/z1"] },
      { name = "zone2", private_dns_zone_ids = ["/subscriptions/x/providers/Microsoft.Network/privateDnsZones/z2"] },
    ]
  }
  expect_failures = [var.private_dns_zone_group]
}

run "rejects_zero_private_service_connections" {
  command = plan
  variables {
    private_service_connections = []
  }
  expect_failures = [var.private_service_connections]
}

run "rejects_more_than_one_private_service_connection" {
  command = plan
  variables {
    private_service_connections = [
      {
        name                           = "psc1"
        is_manual_connection           = false
        private_connection_resource_id = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv1"
      },
      {
        name                           = "psc2"
        is_manual_connection           = false
        private_connection_resource_id = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv2"
      },
    ]
  }
  expect_failures = [var.private_service_connections]
}

run "rejects_connection_with_neither_resource_id_nor_alias" {
  command = plan
  variables {
    private_service_connections = [{
      name                 = "psc-bad"
      is_manual_connection = false
    }]
  }
  expect_failures = [var.private_service_connections]
}

run "rejects_connection_with_both_resource_id_and_alias" {
  command = plan
  variables {
    private_service_connections = [{
      name                              = "psc-bad"
      is_manual_connection              = false
      private_connection_resource_id    = "/subscriptions/x/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv1"
      private_connection_resource_alias = "kv1.vault.core.windows.net.alias"
    }]
  }
  expect_failures = [var.private_service_connections]
}

run "accepts_connection_by_alias_instead_of_resource_id" {
  # The alias path (cross-tenant / cross-subscription connections) is a
  # real, documented alternative to private_connection_resource_id and had
  # no coverage at all before this run.
  command = plan
  variables {
    private_service_connections = [{
      name                              = "psc-alias"
      is_manual_connection              = true
      private_connection_resource_alias = "kv1.vault.core.windows.net.azure.privatelinkservice"
      request_message                   = "please approve"
    }]
  }

  assert {
    condition     = azurerm_private_endpoint.private_endpoint.private_service_connection[0].private_connection_resource_alias == "kv1.vault.core.windows.net.azure.privatelinkservice"
    error_message = "alias-based connection should be accepted and wired through"
  }
}

run "ip_configurations_dynamic_block_renders" {
  # Never previously tested - a pure static ip_configurations block, default [].
  command = plan
  variables {
    ip_configurations = [{
      name               = "ipconfig1"
      private_ip_address = "10.0.0.10"
      subresource_name   = "vault"
      member_name        = "default"
    }]
  }

  assert {
    condition     = length(local.ip_configurations) == 1 && local.ip_configurations["ipconfig1"].private_ip_address == "10.0.0.10"
    error_message = "ip_configurations should be keyed by name and carry through the private IP"
  }
}
