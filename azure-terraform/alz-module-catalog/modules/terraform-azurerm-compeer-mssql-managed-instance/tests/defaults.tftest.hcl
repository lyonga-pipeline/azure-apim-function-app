mock_provider "azurerm" {}
variables {
  name                         = "sqlmi-platform"
  resource_group_name          = "rg-sqlmi"
  location                     = "eastus2"
  administrator_login          = "miadmin"
  administrator_login_password = "P@ssw0rd-Mi-1234567"
  license_type                 = "BasePrice"
  sku_name                     = "GP_Gen5"
  storage_size_in_gb           = 32
  subnet_id                    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet/subnets/sqlmi"
  vcores                       = 4
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_mssql_managed_instance.mssql_managed_instance.name == "sqlmi-platform"
    error_message = "managed instance name not wired"
  }
}
