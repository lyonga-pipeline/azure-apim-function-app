mock_provider "azurerm" {}
variables {
  name      = "appdb"
  server_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sql/providers/Microsoft.Sql/servers/sql-platform"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_mssql_database.mssql_database.name == "appdb"
    error_message = "database name not wired"
  }
}
