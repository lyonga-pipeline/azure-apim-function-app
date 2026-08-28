module "rg" {
  source           = "Azure/avm-res-resources-resourcegroup/azurerm"
  version          = "0.4.0"
  name             = "${var.prefix}-${var.environment}-cus-connectivity-rg"
  location         = var.location
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
  lock             = local.lock
}

module "hub_nsg" {
  for_each = { for k, v in var.subnets : k => v if !contains(["GatewaySubnet"], k) }
  source   = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version  = "0.5.1"

  name                = "${var.prefix}-${var.environment}-cus-${lower(each.key)}-nsg"
  location            = var.location
  resource_group_name = module.rg.name
  security_rules = {
    deny_internet_inbound = {
      name                       = "Deny-Internet-Inbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
  }
  diagnostic_settings = {
    law = { workspace_resource_id = var.log_analytics_workspace_id }
  }
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}

module "hub_route_table" {
  for_each = var.hub_route_tables
  source   = "Azure/avm-res-network-routetable/azurerm"
  version  = "0.5.0"

  name                          = "${var.prefix}-${var.environment}-cus-${each.key}-rt"
  location                      = var.location
  resource_group_name           = module.rg.name
  bgp_route_propagation_enabled = try(each.value.bgp_route_propagation_enabled, true)
  routes                        = try(each.value.routes, {})
  tags                          = local.tags
  enable_telemetry              = var.enable_telemetry
}

module "hub_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.19.0"

  name          = "${var.prefix}-${var.environment}-cus-hub-vnet"
  location      = var.location
  parent_id     = module.rg.resource_id
  address_space = var.hub_address_space
  ipam_pools = [{
    id            = "/subscriptions/${var.subscription_id}/resourceGroups/${module.rg.name}/providers/Microsoft.Network/networkManagers/${var.prefix}-${var.environment}-cus-networkmanager/ipamPools/hub-vnet-pool"
    prefix_length = 24
  }]

  subnets = {
    for name, cfg in var.subnets : name => {
      name                   = name
      address_prefixes       = cfg.address_prefixes
      network_security_group = name == "GatewaySubnet" ? null : { resource_id = module.hub_nsg[name].resource_id }
      route_table = try(cfg.route_table_key, null) == null ? null : {
        resource_id = module.hub_route_table[cfg.route_table_key].resource_id
      }
      default_outbound_access_enabled   = false
      private_endpoint_network_policies = name == "SharedServicesSubnet" ? "Disabled" : "Enabled"
    }
  }
  diagnostic_settings = {
    law = { workspace_resource_id = var.log_analytics_workspace_id }
  }
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
  lock             = local.lock
}

module "spoke_default_route" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.5.0"

  name                          = "${var.prefix}-${var.environment}-cus-spoke-default-rt"
  location                      = var.location
  resource_group_name           = module.rg.name
  bgp_route_propagation_enabled = true
  routes = length(var.spoke_default_routes) == 0 ? {
    default_to_palo_trust = {
      name                   = "default-to-palo-trust"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.palo_trust_ilb_ip
    }
  } : var.spoke_default_routes
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}

# Workbook NET-37: Standard/zone-redundant public IPs reserved for firewall egress.
module "firewall_egress_pip" {
  for_each = toset(["01", "02"])
  source   = "Azure/avm-res-network-publicipaddress/azurerm"
  version  = "0.2.1"

  name                 = "${var.prefix}-${var.environment}-cus-palo-egress-pip-${each.key}"
  location             = var.location
  resource_group_name  = module.rg.name
  allocation_method    = "Static"
  sku                  = "Standard"
  sku_tier             = "Regional"
  zones                = ["1", "2", "3"]
  ddos_protection_mode = "VirtualNetworkInherited"
  tags                 = local.tags
  enable_telemetry     = var.enable_telemetry
}

# Private-link DNS zones are centralized and linked to VNets. Add additional zones
# to the input as services are approved; avoid creating ad-hoc zones in workload roots.
module "private_dns" {
  source  = "Azure/avm-ptn-network-private-link-private-dns-zones/azurerm"
  version = "0.23.2"

  location  = var.location
  parent_id = module.rg.resource_id
  virtual_network_link_default_virtual_networks = {
    hub = {
      virtual_network_resource_id = module.hub_vnet.resource_id
    }
  }
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}

# NET-27 is an explicit architecture switch because the workbook leaves Azure Private
# DNS Resolver vs DC-hosted DNS open. Do not enable this until the network architect decides.
module "dns_resolver" {
  count   = var.enable_private_dns_resolver ? 1 : 0
  source  = "Azure/avm-res-network-dnsresolver/azurerm"
  version = "0.8.0"

  name                        = "${var.prefix}-${var.environment}-cus-dnspr"
  location                    = var.location
  resource_group_name         = module.rg.name
  virtual_network_resource_id = module.hub_vnet.resource_id
  tags                        = local.tags
  enable_telemetry            = var.enable_telemetry
}

# NET-18: vnetgateway pattern. The module is pinned and the architecture contract is
# provided separately because circuit IDs, BGP ASN and ER authorization are workbook decisions.
module "expressroute_gateway" {
  source  = "Azure/avm-ptn-vnetgateway/azurerm"
  version = "0.10.3"

  location           = var.location
  parent_id          = module.rg.resource_id
  virtual_network_id = module.hub_vnet.resource_id
  type               = "ExpressRoute"
  sku                = "ErGw3AZ"
  name               = "${var.prefix}-${var.environment}-cus-ergw"
  tags               = local.tags
  enable_telemetry   = var.enable_telemetry
}


# NET-13 / NET-14: Palo Alto HA trust/untrust internal load balancers.
# Backend NIC/IP associations are intentionally separate because Palo Alto VM
# provisioning is a vendor boundary in the component sheet.
module "palo_trust_ilb" {
  source  = "Azure/avm-res-network-loadbalancer/azurerm"
  version = "0.5.0"

  name                = "${var.prefix}-${var.environment}-cus-palo-trust-ilb"
  location            = var.location
  resource_group_name = module.rg.name
  sku                 = "Standard"
  sku_tier            = "Regional"

  frontend_ip_configurations = {
    trust = {
      name                                   = "trust"
      frontend_private_ip_address_allocation = "Static"
      frontend_private_ip_address            = var.palo_trust_ilb_ip
      frontend_private_ip_subnet_resource_id = module.hub_vnet.subnets["TrustSubnet"].resource_id
    }
  }
  backend_address_pools          = { palo = { name = "palo-trust-pool" } }
  backend_address_pool_addresses = var.palo_trust_backend_addresses
  lb_probes = {
    health = {
      name                            = "tcp-health"
      protocol                        = "Tcp"
      port                            = var.palo_health_probe_port
      interval_in_seconds             = 5
      number_of_probes_before_removal = 2
    }
  }
  lb_rules = {
    ha_ports = {
      name                             = "ha-ports"
      frontend_ip_configuration_name   = "trust"
      backend_address_pool_object_name = "palo-trust-pool"
      protocol                         = "All"
      frontend_port                    = 0
      backend_port                     = 0
      probe_object_name                = "tcp-health"
      enable_floating_ip               = true
      idle_timeout_in_minutes          = 15
      load_distribution                = "Default"
    }
  }
  diagnostic_settings = { law = { workspace_resource_id = var.log_analytics_workspace_id } }
  tags                = local.tags
  lock                = local.lock
  enable_telemetry    = var.enable_telemetry
}

module "palo_untrust_ilb" {
  source  = "Azure/avm-res-network-loadbalancer/azurerm"
  version = "0.5.0"

  name                = "${var.prefix}-${var.environment}-cus-palo-untrust-ilb"
  location            = var.location
  resource_group_name = module.rg.name
  sku                 = "Standard"
  sku_tier            = "Regional"

  frontend_ip_configurations = {
    untrust = {
      name                                   = "untrust"
      frontend_private_ip_address_allocation = "Static"
      frontend_private_ip_address            = var.palo_untrust_ilb_ip
      frontend_private_ip_subnet_resource_id = module.hub_vnet.subnets["UntrustSubnet"].resource_id
    }
  }
  backend_address_pools          = { palo = { name = "palo-untrust-pool" } }
  backend_address_pool_addresses = var.palo_untrust_backend_addresses
  lb_probes = {
    health = {
      name                            = "tcp-health"
      protocol                        = "Tcp"
      port                            = var.palo_health_probe_port
      interval_in_seconds             = 5
      number_of_probes_before_removal = 2
    }
  }
  lb_rules = {
    ha_ports = {
      name                             = "ha-ports"
      frontend_ip_configuration_name   = "untrust"
      backend_address_pool_object_name = "palo-untrust-pool"
      protocol                         = "All"
      frontend_port                    = 0
      backend_port                     = 0
      probe_object_name                = "tcp-health"
      enable_floating_ip               = true
      idle_timeout_in_minutes          = 15
      load_distribution                = "Default"
    }
  }
  diagnostic_settings = { law = { workspace_resource_id = var.log_analytics_workspace_id } }
  tags                = local.tags
  lock                = local.lock
  enable_telemetry    = var.enable_telemetry
}

# SEC-12: optional privileged path. Keep feature-switchable until architecture decision.
module "bastion" {
  count   = var.enable_bastion ? 1 : 0
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "0.9.0"

  name                      = "${var.prefix}-${var.environment}-cus-bas"
  location                  = var.location
  parent_id                 = module.rg.resource_id
  sku                       = "Premium"
  copy_paste_enabled        = true
  file_copy_enabled         = false
  ip_connect_enabled        = true
  tunneling_enabled         = true
  kerberos_enabled          = true
  session_recording_enabled = true
  scale_units               = 2
  ip_configuration = {
    name             = "bastion-ipconfig"
    subnet_id        = module.hub_vnet.subnets["AzureBastionSubnet"].resource_id
    create_public_ip = true
  }
  diagnostic_settings = { law = { workspace_resource_id = var.log_analytics_workspace_id } }
  tags                = local.tags
  lock                = local.lock
  enable_telemetry    = var.enable_telemetry
}
