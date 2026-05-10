application_name = "integration"
environment      = "prod"
location         = "eastus2"
tenant_id        = "00000000-0000-0000-0000-000000000001"

tags = {
  owner       = "integration-team"
  cost_center = "shared-services"
}

resource_group = {}

log_analytics = {
  retention_in_days = 30
}

application_insights = {
  application_type = "web"
}

virtual_network = {
  address_space = ["10.120.0.0/16"]
  subnets = {
    function-integration = {
      address_prefixes = ["10.120.1.0/24"]
      delegations = {
        serverfarms = {
          name = "Microsoft.Web/serverFarms"
        }
      }
    }
    container-workers = {
      address_prefixes = ["10.120.2.0/24"]
    }
    private-endpoints = {
      address_prefixes                  = ["10.120.3.0/24"]
      private_endpoint_network_policies = "Disabled"
    }
  }
}

route_table = {
  routes = {
    default-egress = {
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  }
}

nat_public_ip = {}

nat_gateway = {
  zones = ["1"]
}

private_dns_zones = {
  web = {
    name                = "privatelink.azurewebsites.net"
    resource_group_name = "integration-prod-dns-rg"
  }
  kv = {
    name                = "privatelink.vaultcore.azure.net"
    resource_group_name = "integration-prod-dns-rg"
  }
}

private_dns_links = {
  web = {
    name                  = "integration-prod-web-link"
    resource_group_name   = "integration-prod-dns-rg"
    private_dns_zone_name = "privatelink.azurewebsites.net"
  }
  kv = {
    name                  = "integration-prod-kv-link"
    resource_group_name   = "integration-prod-dns-rg"
    private_dns_zone_name = "privatelink.vaultcore.azure.net"
  }
}

key_vault = {
  enable_rbac_authorization     = true
  public_network_access_enabled = false
}

key_vault_secrets = {
  integration-api-token = {
    value = "replace-me-api-token"
  }
}

storage_account = {
  name                            = "intprodworkflowsa01"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  public_network_access_enabled   = false
  default_to_oauth_authentication = true
  network_rules = {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

storage_containers = {
  deadletter = {
    container_access_type = "private"
  }
  payloads = {
    container_access_type = "private"
  }
}

storage_queues = {
  integrationevents = {}
}

storage_tables = {
  integrationstate = {}
}

storage_shares = {
  workershare = {
    quota = 100
  }
}

app_service_plan = {
  os_type  = "Linux"
  sku_name = "P1v3"
}

function_app = {
  os_type                       = "Linux"
  public_network_access_enabled = false
  https_only                    = true
  identity = {
    type = "SystemAssigned"
  }
  integration_subnet_name = "function-integration"
  storage                 = {}
  site_config = {
    always_on               = true
    http2_enabled           = true
    minimum_tls_version     = "1.2"
    scm_minimum_tls_version = "1.2"
    vnet_route_all_enabled  = true
    application_stack = {
      node_version = "20"
    }
  }
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "node"
    APP_ENVIRONMENT          = "prod"
  }
}

function_app_slot = {
  name    = "staging"
  os_type = "Linux"
  storage = {}
  site_config = {
    always_on               = true
    http2_enabled           = true
    minimum_tls_version     = "1.2"
    scm_minimum_tls_version = "1.2"
    vnet_route_all_enabled  = true
    application_stack = {
      node_version = "20"
    }
  }
  app_settings = {
    APP_ENVIRONMENT = "prod-slot"
  }
}

container_group = {
  subnet_name     = "container-workers"
  os_type         = "Linux"
  ip_address_type = "Private"
  restart_policy  = "OnFailure"
  identity = {
    type = "SystemAssigned"
  }
  containers = {
    worker = {
      image  = "mcr.microsoft.com/azuredocs/aci-helloworld"
      cpu    = 1
      memory = 1.5
      ports = [
        {
          port = 80
        }
      ]
      environment_variables = {
        QUEUE_NAME = "integrationevents"
      }
      volumes = {
        scratch = {
          mount_path = "/mnt/work"
          empty_dir  = true
        }
      }
    }
  }
  exposed_ports = {
    http = {
      port = 80
    }
  }
}

eventgrid_topic = {
  public_network_access_enabled = false
  local_auth_enabled            = false
  identity = {
    type = "SystemAssigned"
  }
}

eventgrid_subscription = {
  included_event_types = ["All"]
  labels               = ["integration", "prod"]
  storage_queue_name   = "integrationevents"
  retry_policy = {
    event_time_to_live    = 1440
    max_delivery_attempts = 10
  }
  dead_letter_destination = {
    storage_blob_container_name = "deadletter"
  }
}

function_app_private_endpoint = {
  subnet_name = "private-endpoints"
  private_service_connection = {
    name              = "integration-prod-func-psc"
    subresource_names = ["sites"]
  }
  private_dns_zone_group = {
    private_dns_zone_ids = ["/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/integration-prod-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net"]
  }
}

key_vault_private_endpoint = {
  subnet_name = "private-endpoints"
  private_service_connection = {
    name              = "integration-prod-kv-psc"
    subresource_names = ["vault"]
  }
  private_dns_zone_group = {
    private_dns_zone_ids = ["/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/integration-prod-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"]
  }
}

function_app_diagnostics = {
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

eventgrid_diagnostics = {
  logs = {
    delivery = {
      category_group = "AllLogs"
    }
  }
  metrics = {
    all = {
      category = "AllMetrics"
    }
  }
}
