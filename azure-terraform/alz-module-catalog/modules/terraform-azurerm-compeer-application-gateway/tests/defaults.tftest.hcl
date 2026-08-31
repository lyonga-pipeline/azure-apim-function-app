mock_provider "azurerm" {}

variables {
  name                = "agw-platform"
  resource_group_name = "rg-edge"
  location            = "eastus2"

  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configurations = {
    default = { subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet/subnets/agw" }
  }

  frontend_ports = {
    https = { port = 443 }
  }

  frontend_ip_configurations = {
    private = {
      subnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet/subnets/agw"
      private_ip_address            = "10.0.0.10"
      private_ip_address_allocation = "Static"
    }
  }

  backend_address_pools = {
    app = { fqdns = ["app.internal.example.com"] }
  }

  backend_http_settings = {
    https = { port = 443, protocol = "Https" }
  }

  http_listeners = {
    https = { frontend_ip_configuration_name = "private", frontend_port_name = "https", protocol = "Https", ssl_certificate_name = "cert" }
  }

  ssl_certificates = {
    cert = { key_vault_secret_id = "https://kv.vault.azure.net/secrets/agw-cert" }
  }

  request_routing_rules = {
    https = { rule_type = "Basic", http_listener_name = "https", backend_address_pool_name = "app", backend_http_settings_name = "https", priority = 100 }
  }
}

run "create" {
  command = apply

  assert {
    condition     = azurerm_application_gateway.this.name == "agw-platform"
    error_message = "name not wired"
  }
  assert {
    condition     = azurerm_application_gateway.this.http2_enabled == true
    error_message = "http2_enabled default not applied (azurerm 4.x attribute)"
  }
}

run "no_op_replan" {
  command = plan
}
