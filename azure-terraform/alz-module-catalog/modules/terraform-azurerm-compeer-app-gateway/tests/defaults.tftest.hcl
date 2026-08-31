mock_provider "azurerm" {}

variables {
  name                = "agw-platform-test"
  resource_group_name = "rg-agw-test"
  location            = "eastus2"

  sku = { name = "Standard_v2", tier = "Standard_v2" }

  gateway_ip_configurations = {
    gwip = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/agw" }
  }
  frontend_ports = { https = { port = 443 } }
  frontend_ip_configurations = {
    public = { public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/publicIPAddresses/pip-agw" }
  }
  http_listeners = {
    https = { frontend_ip_configuration_name = "public", frontend_port_name = "https", protocol = "Https", ssl_certificate_name = "wildcard" }
  }
  backend_address_pools = { app = { fqdns = ["app.internal.example.com"] } }
  backend_http_settings = { app = { port = 443, protocol = "Https" } }
  request_routing_rules = {
    app = { rule_type = "Basic", http_listener_name = "https", backend_address_pool_name = "app", backend_http_settings_name = "app", priority = 100 }
  }
}

run "create" {
  command = apply

  assert {
    condition     = azurerm_application_gateway.main.name == "agw-platform-test"
    error_message = "name not wired"
  }
  assert {
    condition     = length(azurerm_application_gateway.main.request_routing_rule) == 1
    error_message = "expected one routing rule"
  }
  assert {
    condition     = length(azurerm_application_gateway.main.gateway_ip_configuration) == 1
    error_message = "expected one gateway IP config"
  }
}

run "add_backend_pool_is_additive" {
  command = apply

  variables {
    backend_address_pools = {
      app = { fqdns = ["app.internal.example.com"] }
      api = { fqdns = ["api.internal.example.com"] }
    }
  }

  assert {
    condition     = length(azurerm_application_gateway.main.backend_address_pool) == 2
    error_message = "adding a pool key adds one pool"
  }
}
