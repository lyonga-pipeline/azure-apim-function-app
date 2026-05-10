application_name = "webportal"
environment      = "np2"
location         = "eastus2"
tenant_id        = "00000000-0000-0000-0000-000000000001"

tags = {
  owner       = "platform-team"
  cost_center = "digital"
}

resource_group = {
  tags = {
    workload = "web"
  }
}

log_analytics = {
  retention_in_days = 30
}

application_insights = {
  application_type = "web"
}

virtual_network = {
  address_space = ["10.110.0.0/16"]
  subnets = {
    appsvc-integration = {
      address_prefixes = ["10.110.1.0/24"]
      delegations = {
        serverfarms = {
          name = "Microsoft.Web/serverFarms"
        }
      }
    }
    private-endpoints = {
      address_prefixes                  = ["10.110.2.0/24"]
      private_endpoint_network_policies = "Disabled"
    }
  }
}

private_dns_zones = {
  web = {
    name                = "privatelink.azurewebsites.net"
    resource_group_name = "webportal-np2-dns-rg"
  }
  kv = {
    name                = "privatelink.vaultcore.azure.net"
    resource_group_name = "webportal-np2-dns-rg"
  }
  blob = {
    name                = "privatelink.blob.core.windows.net"
    resource_group_name = "webportal-np2-dns-rg"
  }
  file = {
    name                = "privatelink.file.core.windows.net"
    resource_group_name = "webportal-np2-dns-rg"
  }
}

private_dns_links = {
  web = {
    name                  = "webportal-np2-web-link"
    resource_group_name   = "webportal-np2-dns-rg"
    private_dns_zone_name = "privatelink.azurewebsites.net"
  }
  kv = {
    name                  = "webportal-np2-kv-link"
    resource_group_name   = "webportal-np2-dns-rg"
    private_dns_zone_name = "privatelink.vaultcore.azure.net"
  }
  blob = {
    name                  = "webportal-np2-blob-link"
    resource_group_name   = "webportal-np2-dns-rg"
    private_dns_zone_name = "privatelink.blob.core.windows.net"
  }
  file = {
    name                  = "webportal-np2-file-link"
    resource_group_name   = "webportal-np2-dns-rg"
    private_dns_zone_name = "privatelink.file.core.windows.net"
  }
}

key_vault = {
  enable_rbac_authorization     = true
  public_network_access_enabled = false
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
}

key_vault_keys = {
  storage-cmk = {
    key_type = "RSA"
    key_size = 2048
    key_opts = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
    rotation_policy = {
      expire_after         = "P180D"
      notify_before_expiry = "P30D"
      automatic = {
        time_before_expiry = "P29D"
      }
    }
  }
}

key_vault_secrets = {
  webportal-api-key = {
    value        = "replace-me-api-key"
    content_type = "text/plain"
  }
}

storage_account = {
  name                              = "webnp2portalstore01"
  account_tier                      = "Standard"
  account_replication_type          = "ZRS"
  access_tier                       = "Hot"
  public_network_access_enabled     = false
  shared_access_key_enabled         = true
  infrastructure_encryption_enabled = true
  large_file_share_enabled          = true
  default_to_oauth_authentication   = true
  identity = {
    type         = "UserAssigned"
    identity_ids = ["/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/webportal-np2-identity-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/webportal-storage-cmk-id"]
  }
  network_rules = {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
  blob_properties = {
    versioning_enabled              = true
    change_feed_enabled             = true
    delete_retention_days           = 14
    container_delete_retention_days = 14
  }
}

storage_cmk = {
  key_name                            = "storage-cmk"
  user_assigned_identity_id           = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/webportal-np2-identity-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/webportal-storage-cmk-id"
  user_assigned_identity_principal_id = "00000000-0000-0000-0000-000000000101"
}

storage_management_rules = {
  retain-app-content = {
    enabled = true
    filters = {
      blob_types   = ["blockBlob"]
      prefix_match = ["web-assets/"]
    }
    actions = {
      base_blob = {
        tier_to_cool_after_days_since_modification_greater_than = 30
        delete_after_days_since_modification_greater_than       = 365
      }
    }
  }
}

storage_containers = {
  web-assets = {
    container_access_type = "private"
  }
}

storage_shares = {
  web-content = {
    quota = 100
  }
}

storage_blobs = {
  "seed-index.html" = {
    container_name = "web-assets"
    type           = "Block"
    source         = "assets/index.html"
    content_type   = "text/html"
  }
}

app_service_plan = {
  os_type  = "Linux"
  sku_name = "P1v3"
}

web_app = {
  os_type                       = "Linux"
  public_network_access_enabled = false
  https_only                    = true
  identity = {
    type = "SystemAssigned"
  }
  integration_subnet_name = "appsvc-integration"
  site_config = {
    always_on               = true
    http2_enabled           = true
    minimum_tls_version     = "1.2"
    scm_minimum_tls_version = "1.2"
    websockets_enabled      = true
    vnet_route_all_enabled  = true
    health_check_path       = "/healthz"
    application_stack = {
      docker_image_name   = "mcr.microsoft.com/azuredocs/appservice-helloworld:latest"
      docker_registry_url = "https://mcr.microsoft.com"
    }
  }
  auth_settings_v2 = {
    auth_enabled           = true
    require_authentication = true
    require_https          = true
    unauthenticated_action = "RedirectToLoginPage"
    default_provider       = "azureactivedirectory"
    active_directory_v2 = {
      client_id            = "00000000-0000-0000-0000-000000000201"
      tenant_auth_endpoint = "https://login.microsoftonline.com/00000000-0000-0000-0000-000000000001/v2.0"
      allowed_audiences    = ["api://webportal-np2"]
    }
    login = {
      token_store_enabled = true
    }
  }
  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE = "0"
    APP_ENVIRONMENT          = "np2"
  }
}

web_app_slot = {
  name    = "staging"
  os_type = "Linux"
  site_config = {
    always_on               = true
    http2_enabled           = true
    minimum_tls_version     = "1.2"
    scm_minimum_tls_version = "1.2"
    vnet_route_all_enabled  = true
    application_stack = {
      docker_image_name   = "mcr.microsoft.com/azuredocs/appservice-helloworld:latest"
      docker_registry_url = "https://mcr.microsoft.com"
    }
  }
  app_settings = {
    APP_ENVIRONMENT = "np2-slot"
  }
}

web_app_private_endpoint = {
  subnet_name = "private-endpoints"
  private_service_connection = {
    name              = "webportal-np2-web-psc"
    subresource_names = ["sites"]
  }
  private_dns_zone_group = {
    private_dns_zone_ids = ["/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/webportal-np2-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net"]
  }
}

key_vault_private_endpoint = {
  subnet_name = "private-endpoints"
  private_service_connection = {
    name              = "webportal-np2-kv-psc"
    subresource_names = ["vault"]
  }
  private_dns_zone_group = {
    private_dns_zone_ids = ["/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/webportal-np2-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"]
  }
}

storage_blob_private_endpoint = {
  subnet_name = "private-endpoints"
  private_service_connection = {
    name              = "webportal-np2-blob-psc"
    subresource_names = ["blob"]
  }
  private_dns_zone_group = {
    private_dns_zone_ids = ["/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/webportal-np2-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"]
  }
}

storage_file_private_endpoint = {
  subnet_name = "private-endpoints"
  private_service_connection = {
    name              = "webportal-np2-file-psc"
    subresource_names = ["file"]
  }
  private_dns_zone_group = {
    private_dns_zone_ids = ["/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/webportal-np2-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net"]
  }
}

web_app_diagnostics = {
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

key_vault_diagnostics = {
  logs = {
    audit = {
      category = "AuditEvent"
    }
  }
  metrics = {
    all = {
      category = "AllMetrics"
    }
  }
}

storage_diagnostics = {
  logs = {
    blob = {
      category_group = "AllLogs"
    }
  }
  metrics = {
    all = {
      category = "AllMetrics"
    }
  }
}
