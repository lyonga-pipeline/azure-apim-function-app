location    = "eastus"
environment = "np"

platform_tags = {
  application         = "landing-zone-connectivity"
  business_owner      = "Cloud Enablement"
  source_repo         = "ado://Compeer/azure-cloud"
  terraform_workspace = "lz-platform-connectivity-np"
  recovery_tier       = "standard"
  cost_center         = "cloud-platform"
  data_classification = "internal"
  compliance_boundary = "finserv"
  additional_tags = {
    deployment_model = "net-new-lz"
  }
}

resource_group = {
  name = "rg-lz-platform-connectivity-np"
}

hub_vnet = {
  name          = "vnet-lz-hub-np"
  address_space = ["10.40.0.0/20"]
  dns_servers   = ["10.10.10.10", "10.10.10.11"]
  subnets = {
    firewall = {
      address_prefixes = ["10.40.0.0/26"]
    }
    private_endpoints = {
      address_prefixes                  = ["10.40.1.0/24"]
      private_endpoint_network_policies = "Disabled"
    }
    shared_services = {
      address_prefixes = ["10.40.2.0/24"]
    }
    dns_resolver = {
      address_prefixes = ["10.40.3.0/28"]
    }
  }
}

network_security_groups = {
  private_endpoints = {
    name  = "nsg-lz-hub-private-endpoints-np"
    rules = {}
  }
  shared_services = {
    name  = "nsg-lz-hub-shared-services-np"
    rules = {}
  }
}

subnet_nsg_associations = {
  private_endpoints = {
    subnet_key = "private_endpoints"
    nsg_key    = "private_endpoints"
  }
  shared_services = {
    subnet_key = "shared_services"
    nsg_key    = "shared_services"
  }
}

route_tables = {
  shared_services = {
    name = "rt-lz-hub-shared-services-np"
    routes = {
      default_to_firewall = {
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = "10.40.0.4"
      }
    }
  }
}

subnet_route_table_associations = {
  shared_services = {
    subnet_key      = "shared_services"
    route_table_key = "shared_services"
  }
}

private_dns_zones = {
  app_service = {
    name = "privatelink.azurewebsites.net"
  }
  key_vault = {
    name = "privatelink.vaultcore.azure.net"
  }
  storage_blob = {
    name = "privatelink.blob.core.windows.net"
  }
  storage_queue = {
    name = "privatelink.queue.core.windows.net"
  }
  storage_file = {
    name = "privatelink.file.core.windows.net"
  }
}

role_assignments = {}

management_locks = {
  connectivity_rg = {
    name       = "lock-rg-lz-platform-connectivity-np"
    scope_key  = "resource_group"
    lock_level = "CanNotDelete"
    notes      = "Protects shared hub networking and DNS resources."
  }
  hub_vnet = {
    name       = "lock-vnet-lz-hub-np"
    scope_key  = "hub_vnet"
    lock_level = "CanNotDelete"
    notes      = "Protects hub network from accidental deletion."
  }
  private_dns_app_service = {
    name       = "lock-pdns-app-service-np"
    scope_key  = "private_dns_zone:app_service"
    lock_level = "CanNotDelete"
    notes      = "Protects shared private DNS zone used by application private endpoints."
  }
}

diagnostic_settings = {}
