mock_provider "azurerm" {}
variables {
  name                         = "sql-platform"
  resource_group_name          = "rg-sql"
  location                     = "eastus2"
  mssql_server_version         = "12.0"
  administrator_login          = "sqladminuser"
  administrator_login_password = "P@ssw0rd-Sql-123456"
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_mssql_server.mssql_server.name == "sql-platform"
    error_message = "server name not wired"
  }
  assert {
    condition     = azurerm_mssql_server.mssql_server.version == "12.0"
    error_message = "version not wired"
  }
}
run "rejects_bad_identity_type" {
  command = plan
  variables {
    identity = { type = "Nope" }
  }
  expect_failures = [var.identity]
}
