mock_provider "azurerm" {}
variables {
  container_name      = "ci-platform"
  resource_group_name = "rg-ci"
  location            = "eastus2"
  ip_address_type     = "Public"
  container_info = {
    app = {
      name   = "app"
      image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
      cpu    = 1
      memory = 1.5
      ports  = { http = { port = 80, protocol = "TCP" } }
    }
  }
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_container_group.container.name == "ci-platform"
    error_message = "name not wired"
  }
}
run "requires_a_container" {
  command = plan
  variables { container_info = {} }
  expect_failures = [var.container_info]
}
