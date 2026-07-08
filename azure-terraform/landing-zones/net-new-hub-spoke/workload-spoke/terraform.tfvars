location    = "eastus"
environment = "np1"

workload_tags = {
  application         = "online-banking"
  business_owner      = "Digital Banking"
  source_repo         = "ado://Compeer/online-banking"
  terraform_workspace = "lz-workload-online-banking-np1"
  recovery_tier       = "standard"
  cost_center         = "CC-100145"
  data_classification = "confidential"
  compliance_boundary = "finserv"
  additional_tags = {
    deployment_model = "net-new-lz"
  }
}

resource_group = {
  name = "rg-online-banking-np1-network"
}

spoke_vnet = {
  name          = "vnet-online-banking-np1"
  address_space = ["10.50.0.0/22"]
  dns_servers   = ["10.10.10.10", "10.10.10.11"]
  subnets = {
    app_integration = {
      address_prefixes = ["10.50.0.0/24"]
      delegations = {
        app_service = {
          name    = "Microsoft.Web/serverFarms"
          actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    }
    private_endpoints = {
      address_prefixes                  = ["10.50.1.0/24"]
      private_endpoint_network_policies = "Disabled"
    }
    app = {
      address_prefixes = ["10.50.2.0/24"]
    }
  }
}

network_security_groups = {
  app = {
    name  = "nsg-online-banking-np1"
    rules = {}
  }
  private_endpoints = {
    name  = "nsg-online-banking-np1-private-endpoints"
    rules = {}
  }
}

subnet_nsg_associations = {
  app = {
    subnet_key = "app"
    nsg_key    = "app"
  }
  private_endpoints = {
    subnet_key = "private_endpoints"
    nsg_key    = "private_endpoints"
  }
}

route_tables = {
  app = {
    name = "rt-online-banking-np1-app"
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
  app = {
    subnet_key      = "app"
    route_table_key = "app"
  }
}

hub_connection         = null
private_dns_zone_links = {}

role_assignments = {}

management_locks = {
  workload_network_rg = {
    name       = "lock-rg-online-banking-np1-network"
    scope_key  = "resource_group"
    lock_level = "CanNotDelete"
    notes      = "Protects workload network foundation from accidental deletion."
  }
  spoke_vnet = {
    name       = "lock-vnet-online-banking-np1"
    scope_key  = "spoke_vnet"
    lock_level = "CanNotDelete"
    notes      = "Protects workload spoke VNet from accidental deletion."
  }
}

diagnostic_settings = {}
