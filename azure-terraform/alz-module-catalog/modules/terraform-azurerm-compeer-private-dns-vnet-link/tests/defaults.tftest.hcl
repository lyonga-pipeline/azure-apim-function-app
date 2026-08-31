mock_provider "azurerm" {}
variables {
  links = {
    hub-kv = {
      name                  = "lnk-kv-hub"
      resource_group_name   = "rg-dns"
      private_dns_zone_name = "privatelink.vaultcore.azure.net"
      virtual_network_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
    }
  }
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_private_dns_zone_virtual_network_link.this["hub-kv"].registration_enabled == false
    error_message = "registration_enabled should default false"
  }
}
