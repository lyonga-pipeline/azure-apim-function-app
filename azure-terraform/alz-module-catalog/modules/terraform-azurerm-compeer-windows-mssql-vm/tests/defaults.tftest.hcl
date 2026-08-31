mock_provider "azurerm" {}

variables {
  virtual_machine_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Compute/virtualMachines/vm-sql01"
  sql_connectivity_update_username = "sqladmin"
  sql_connectivity_update_password = "Sup3rSecretP@ssw0rd!"
}

run "defaults" {
  command = apply

  assert {
    condition     = azurerm_mssql_virtual_machine.mssql_virtual_machine.sql_connectivity_type == "PRIVATE"
    error_message = "connectivity type should default to PRIVATE"
  }
  assert {
    condition     = azurerm_mssql_virtual_machine.mssql_virtual_machine.sql_license_type == "PAYG"
    error_message = "license type should default to PAYG"
  }
}

run "local_connectivity_needs_no_creds" {
  command = plan
  variables {
    sql_connectivity_type            = "LOCAL"
    sql_connectivity_update_username = null
    sql_connectivity_update_password = null
  }
}

run "rejects_private_without_creds" {
  command = plan
  variables {
    sql_connectivity_update_username = null
    sql_connectivity_update_password = null
  }
  expect_failures = [azurerm_mssql_virtual_machine.mssql_virtual_machine]
}

run "rejects_bad_connectivity_type" {
  command = plan
  variables { sql_connectivity_type = "REMOTE" }
  expect_failures = [var.sql_connectivity_type]
}

run "rejects_bad_license_type" {
  command = plan
  variables { sql_license_type = "FREE" }
  expect_failures = [var.sql_license_type]
}
