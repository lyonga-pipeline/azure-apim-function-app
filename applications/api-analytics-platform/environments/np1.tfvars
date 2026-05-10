application_name = "apianalytics"
environment      = "np1"
location         = "eastus2"
tenant_id        = "00000000-0000-0000-0000-000000000001"

tags = {
  owner       = "platform-api-team"
  cost_center = "api-data"
}

resource_group = {}

log_analytics = {
  retention_in_days = 30
}

virtual_network = {
  address_space = ["10.140.0.0/16"]
  subnets = {
    application-gateway = {
      address_prefixes = ["10.140.1.0/24"]
    }
    apim = {
      address_prefixes = ["10.140.2.0/24"]
    }
  }
}

private_dns_zones = {
  internal = {
    name                = "contoso.internal"
    resource_group_name = "apianalytics-np1-dns-rg"
  }
}

private_dns_links = {
  internal = {
    name                  = "apianalytics-np1-internal-link"
    resource_group_name   = "apianalytics-np1-dns-rg"
    private_dns_zone_name = "contoso.internal"
  }
}

private_dns_records = {
  api = {
    name                = "api"
    zone_name           = "contoso.internal"
    resource_group_name = "apianalytics-np1-dns-rg"
    ttl                 = 300
  }
}

gateway_public_ip = {}

key_vault = {
  public_network_access_enabled = false
}

key_vault_secrets = {
  apim-backend-key = {
    value = "replace-me-backend-key"
  }
}

key_vault_certificates = {
  gateway = {
    issuer_name        = "Self"
    subject            = "CN=api.np1.contoso.internal"
    validity_in_months = 12
    subject_alternative_names = {
      dns_names = ["api.np1.contoso.internal"]
    }
  }
}

key_vault_managed_hsm = {
  admin_object_ids = ["00000000-0000-0000-0000-000000000401"]
}

storage_account = {
  name                          = "apianp1synstore01"
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "StorageV2"
  access_tier                   = "Hot"
  public_network_access_enabled = false
}

synapse_filesystem = {
  name = "datalake"
}

synapse_workspace = {
  sql_administrator_login              = "synapseadmin"
  sql_administrator_login_password     = "ReplaceMe!123456"
  managed_virtual_network_enabled      = true
  data_exfiltration_protection_enabled = true
  identity = {
    type = "SystemAssigned"
  }
}

synapse_workspace_aad_admin = {
  login     = "analytics-admins"
  object_id = "00000000-0000-0000-0000-000000000402"
}

application_gateway = {
  gateway_subnet_name = "application-gateway"
  enable_http2        = true
  sku = {
    name = "WAF_v2"
    tier = "WAF_v2"
  }
  autoscale_configuration = {
    min_capacity = 1
    max_capacity = 3
  }
  frontend_ports = {
    http = {
      port = 80
    }
  }
  backend_address_pools = {
    apim = {
      fqdns = ["api.np1.contoso.internal"]
    }
  }
  probes = {
    apim = {
      protocol = "Http"
      path     = "/status-0123456789abcdef"
      host     = "api.np1.contoso.internal"
    }
  }
  backend_http_settings = {
    apim = {
      port            = 80
      protocol        = "Http"
      request_timeout = 30
      probe_name      = "apim"
      host_name       = "api.np1.contoso.internal"
    }
  }
  http_listeners = {
    public = {
      frontend_ip_configuration_name = "public"
      frontend_port_name             = "http"
      protocol                       = "Http"
      host_name                      = "api.np1.contoso.internal"
    }
  }
  waf_configuration = {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_version = "3.2"
  }
  request_routing_rules = {
    apim = {
      rule_type                  = "Basic"
      http_listener_name         = "public"
      backend_address_pool_name  = "apim"
      backend_http_settings_name = "apim"
      priority                   = 100
    }
  }
}

apim_service = {
  publisher_name                = "Compeer Platform"
  publisher_email               = "platform@example.com"
  sku_name                      = "Developer_1"
  public_network_access_enabled = false
  virtual_network_type          = "Internal"
  subnet_name                   = "apim"
  identity = {
    type         = "UserAssigned"
    identity_ids = ["/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/apianalytics-np1-identity-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/apim-np1-mi"]
  }
  identity_principal_id = "00000000-0000-0000-0000-000000000403"
  protocols = {
    enable_http2 = true
  }
}

apim_custom_domain = {
  gateway = {
    "api.np1.contoso.internal" = {
      certificate_name    = "gateway"
      default_ssl_binding = true
    }
  }
}

apim_named_values = {
  backend-key = {
    display_name    = "backend-key"
    secret          = true
    secret_key_name = "apim-backend-key"
  }
}

apim_backend = {
  protocol = "http"
  url      = "https://backend.np1.contoso.internal"
  title    = "np1-backend"
  credentials = {
    header = {
      "x-api-key" = "{{backend-key}}"
    }
  }
}

apim_api = {
  name                  = "orders"
  display_name          = "Orders API"
  path                  = "orders"
  protocols             = ["https"]
  service_url           = "https://backend.np1.contoso.internal/orders"
  subscription_required = true
  api_type              = "http"
  description           = "Orders API facade"
}

apim_policy = {
  xml_content = <<-XML
  <policies>
    <inbound>
      <base />
    </inbound>
    <backend>
      <base />
    </backend>
    <outbound>
      <base />
    </outbound>
    <on-error>
      <base />
    </on-error>
  </policies>
  XML
}

apim_api_policy = {
  xml_content = <<-XML
  <policies>
    <inbound>
      <base />
      <set-backend-service backend-id="apianalytics-np1-backend" />
    </inbound>
    <backend>
      <base />
    </backend>
    <outbound>
      <base />
    </outbound>
    <on-error>
      <base />
    </on-error>
  </policies>
  XML
}

apim_product = {
  product_id            = "orders-product"
  display_name          = "Orders Product"
  approval_required     = false
  published             = true
  subscription_required = true
}

apim_product_apis = {
  orders = {
    product_id = "orders-product"
    api_name   = "orders"
  }
}

apim_diagnostics = {
  logs = {
    all = {
      category_group = "AllLogs"
    }
  }
  metrics = {
    all = {
      category = "AllMetrics"
    }
  }
}

synapse_diagnostics = {
  logs = {
    all = {
      category_group = "AllLogs"
    }
  }
  metrics = {
    all = {
      category = "AllMetrics"
    }
  }
}
