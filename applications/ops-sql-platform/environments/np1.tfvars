application_name = "opssql"
environment      = "np1"
location         = "eastus2"
tenant_id        = "00000000-0000-0000-0000-000000000001"

tags = {
  owner       = "operations-team"
  cost_center = "operations"
}

resource_group = {}

log_analytics = {
  retention_in_days = 30
}

action_group = {
  short_name = "opsnp1"
  receivers = {
    email = {
      primary = {
        email_address = "ops-team@example.com"
      }
    }
  }
}

virtual_network = {
  address_space = ["10.130.0.0/16"]
  subnets = {
    servers = {
      address_prefixes = ["10.130.1.0/24"]
    }
    private-endpoints = {
      address_prefixes                  = ["10.130.2.0/24"]
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

network_security_group = {
  rules = {
    rdp = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "3389"
    }
    sql = {
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "10.130.0.0/16"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "1433"
    }
  }
}

private_dns_zones = {
  sql = {
    name                = "privatelink.database.windows.net"
    resource_group_name = "opssql-np1-dns-rg"
  }
  internal = {
    name                = "ops.internal"
    resource_group_name = "opssql-np1-dns-rg"
  }
}

private_dns_links = {
  sql = {
    name                  = "opssql-np1-sql-link"
    resource_group_name   = "opssql-np1-dns-rg"
    private_dns_zone_name = "privatelink.database.windows.net"
  }
  internal = {
    name                  = "opssql-np1-internal-link"
    resource_group_name   = "opssql-np1-dns-rg"
    private_dns_zone_name = "ops.internal"
  }
}

private_dns_records = {
  jumphost = {
    name                = "jump"
    zone_name           = "ops.internal"
    resource_group_name = "opssql-np1-dns-rg"
    ttl                 = 300
  }
}

nat_public_ip = {}

nat_gateway = {}

load_balancer_public_ip = {}

storage_account = {
  name                          = "opssqlnp1diag01"
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  public_network_access_enabled = false
}

key_vault = {
  public_network_access_enabled = false
}

key_vault_secrets = {
  vm-admin-password = {
    value = "ReplaceMe!123456"
  }
}

key_vault_access_policies = {
  platform-operator = {
    tenant_id          = "00000000-0000-0000-0000-000000000001"
    object_id          = "00000000-0000-0000-0000-000000000301"
    secret_permissions = ["Get", "List", "Set"]
  }
}

network_interface = {
  subnet_name                    = "servers"
  primary_ip_configuration_name  = "primary"
  accelerated_networking_enabled = true
  ip_configurations = {
    primary = {
      private_ip_address_allocation = "Dynamic"
      primary                       = true
    }
  }
}

application_security_group = {
  name = "opssql-np1-asg"
}

availability_set = {}

windows_vm = {
  vm_size        = "Standard_D4s_v5"
  admin_username = "azureadmin"
  admin_password = "ReplaceMe!123456"
  identity = {
    type = "SystemAssigned"
  }
  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }
}

windows_vm_data_disks = {
  disks = {
    data = {
      lun                  = 0
      disk_size_gb         = 256
      storage_account_type = "Premium_LRS"
      caching              = "ReadOnly"
    }
    logs = {
      lun                  = 1
      disk_size_gb         = 128
      storage_account_type = "Premium_LRS"
      caching              = "None"
    }
  }
}

windows_vm_domain_join = {
  domain_name     = "corp.contoso.com"
  domain_username = "CORP\\svc-domainjoin"
  domain_password = "ReplaceMe!123456"
  ou_path         = "OU=Servers,DC=corp,DC=contoso,DC=com"
}

windows_vm_extensions = {
  customscript = {
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.10"
    settings = {
      commandToExecute = "powershell.exe -Command \"Write-Host ops-sql-platform\""
    }
  }
}

load_balancer = {
  primary_backend_pool_name = "servers"
  backend_address_pools = {
    servers = {}
  }
  probes = {
    rdp = {
      protocol = "Tcp"
      port     = 3389
    }
  }
  rules = {
    rdp = {
      protocol                       = "Tcp"
      frontend_port                  = 3389
      backend_port                   = 3389
      frontend_ip_configuration_name = "public"
      backend_address_pool_names     = ["servers"]
      probe_name                     = "rdp"
    }
  }
}

sql_server = {
  azuread_authentication_only = true
  azuread_administrator = {
    login_username = "sql-admin-group"
    object_id      = "00000000-0000-0000-0000-000000000302"
  }
}

sql_databases = {
  appdb = {
    sku_name    = "GP_S_Gen5_2"
    max_size_gb = 32
  }
}

sql_auditing_policy = {
  enabled                = true
  log_monitoring_enabled = true
  retention_in_days      = 30
}

sql_security_alert_policy = {
  state                = "Enabled"
  email_account_admins = true
  email_addresses      = ["dba@example.com"]
  retention_days       = 30
}

sql_private_endpoint = {
  subnet_name = "private-endpoints"
  private_service_connection = {
    name              = "opssql-np1-sql-psc"
    subresource_names = ["sqlServer"]
  }
  private_dns_zone_group = {
    private_dns_zone_ids = ["/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/opssql-np1-dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net"]
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

sql_diagnostics = {
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
