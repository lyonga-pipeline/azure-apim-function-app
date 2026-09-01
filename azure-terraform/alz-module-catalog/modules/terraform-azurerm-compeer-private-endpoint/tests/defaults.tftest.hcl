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
  private_dns_zone_group = [{
    name                 = "default"
    private_dns_zone_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"]
  }]
}

run "create" {
  command = apply
  assert {
    condition     = azurerm_private_endpoint.private_endpoint.name == "pep-kv-platform"
    error_message = "name not wired"
  }
  assert {
    condition     = azurerm_private_endpoint.private_endpoint.subnet_id == var.subnet_id
    error_message = "subnet not wired"
  }
}

run "no_op_replan" {
  command = plan
}
