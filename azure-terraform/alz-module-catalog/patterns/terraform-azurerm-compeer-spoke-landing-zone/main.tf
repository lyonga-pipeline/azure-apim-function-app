module "naming" {
  source                      = "../../modules/terraform-azurerm-compeer-naming"
  scope                       = "workload"
  region                      = var.location
  environment                 = var.environment
  domain                      = var.domain
  appcode                     = var.appcode
  resource_group_keys         = local.resource_group_keys
  storage_account_keys        = keys(var.storage_accounts)
  storage_uniqueness          = var.subscription_id
  subnet_keys                 = keys(var.subnets)
  nsg_keys                    = keys(var.subnets)
  route_table_keys            = keys(var.subnets)
  user_assigned_identity_keys = ["workload"]
}

module "tags" {
  source              = "../../modules/terraform-azurerm-compeer-platform-tags"
  environment         = var.environment
  appcode             = var.appcode
  application         = var.workload_tags.application
  owner               = var.workload_tags.owner
  source_repo         = var.workload_tags.source_repo
  created_on          = var.workload_tags.created_on
  criticality_tier    = var.workload_tags.criticality_tier
  data_classification = var.workload_tags.data_classification
  lifecycle_state     = var.workload_tags.lifecycle_state
  cost_center         = var.workload_tags.cost_center
  gl_category         = var.workload_tags.gl_category
  dr_tier             = var.workload_tags.dr_tier
  additional_tags     = var.workload_tags.additional_tags
}

module "resource_groups" {
  source = "../../modules/terraform-azurerm-compeer-resource-group"
  resource_groups = { for key in local.resource_group_keys : key => {
    name     = module.naming.resource_group_names[key]
    location = var.location
    tags     = module.tags.tags
  } }
  depends_on = [terraform_data.contracts]
}

module "network" {
  source                  = "../../modules/terraform-azurerm-compeer-virtual-network"
  name                    = module.naming.workload_vnet
  resource_group_name     = module.resource_groups.group_names["network"]
  location                = var.location
  address_space           = var.address_space
  dns_servers             = var.platform.dns_server_ips
  ddos_protection_plan_id = var.platform.ddos_protection_plan_id
  subnets = { for key, subnet in var.subnets : module.naming.subnet_names[key] => {
    address_prefixes                              = subnet.address_prefixes
    service_endpoints                             = subnet.service_endpoints
    default_outbound_access_enabled               = false
    private_endpoint_network_policies             = "Enabled"
    private_link_service_network_policies_enabled = true
    delegations                                   = subnet.delegations
  } }
  tags = module.tags.tags
}

locals {
  subnet_ids = { for key in keys(var.subnets) : key => module.network.subnet_ids[module.naming.subnet_names[key]] }
  baseline_rules = { for key, subnet in var.subnets : key => merge(
    {
      baseline-deny-inbound = {
        protocol = "*", source_port_range = "*", destination_port_range = "*", source_address_prefix = "*", destination_address_prefix = "*",
        access   = "Deny", priority = 4096, direction = "Inbound"
      }
      baseline-deny-outbound = {
        protocol = "*", source_port_range = "*", destination_port_range = "*", source_address_prefix = "*", destination_address_prefix = "*",
        access   = "Deny", priority = 4096, direction = "Outbound"
      }
    },
    { for rule_name, rule in {
      baseline-private-https = {
        protocol                = "Tcp", source_port_range = "*", destination_port_range = "443",
        source_address_prefixes = distinct(concat(var.address_space, var.private_endpoint_client_cidrs)), destination_address_prefix = "*",
        access                  = "Allow", priority = 100, direction = "Inbound"
      }
      } : rule_name => rule if key == "private_endpoints"
    },
    { for rule_name, rule in {
      baseline-health-probe = {
        protocol = "*", source_port_range = "*", destination_port_range = "*", source_address_prefix = "AzureLoadBalancer", destination_address_prefix = "*",
        access   = "Allow", priority = 100, direction = "Inbound"
      }
      baseline-dns-udp = {
        protocol                     = "Udp", source_port_range = "*", destination_port_range = "53", source_address_prefix = "*",
        destination_address_prefix   = length(var.platform.dns_server_ips) == 0 ? "AzurePlatformDNS" : null,
        destination_address_prefixes = length(var.platform.dns_server_ips) > 0 ? toset(var.platform.dns_server_ips) : null,
        access                       = "Allow", priority = 100, direction = "Outbound"
      }
      baseline-dns-tcp = {
        protocol                     = "Tcp", source_port_range = "*", destination_port_range = "53", source_address_prefix = "*",
        destination_address_prefix   = length(var.platform.dns_server_ips) == 0 ? "AzurePlatformDNS" : null,
        destination_address_prefixes = length(var.platform.dns_server_ips) > 0 ? toset(var.platform.dns_server_ips) : null,
        access                       = "Allow", priority = 101, direction = "Outbound"
      }
      baseline-private-https = {
        protocol                     = "Tcp", source_port_range = "*", destination_port_range = "443", source_address_prefix = "*",
        destination_address_prefixes = toset(try(var.subnets.private_endpoints.address_prefixes, [])),
        access                       = "Allow", priority = 110, direction = "Outbound"
      }
      baseline-egress-https = {
        protocol = "Tcp", source_port_range = "*", destination_port_range = "443", source_address_prefix = "*", destination_address_prefix = "Internet",
        access   = "Allow", priority = 200, direction = "Outbound"
      }
      } : rule_name => rule if key != "private_endpoints"
    }
  ) }
  nsg_rules = { for key, subnet in var.subnets : key => {
    for name, rule in merge(local.baseline_rules[key], subnet.rules) : name => merge(rule, { name = name })
  } }
  routes = { for key, subnet in var.subnets : key => merge(subnet.routes, {
    default-egress = { address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = var.egress_next_hop_ip }
  }) }
}

module "network_security_groups" {
  source              = "../../modules/terraform-azurerm-compeer-network-security-group"
  for_each            = var.subnets
  name                = module.naming.nsg_names[each.key]
  resource_group_name = module.resource_groups.group_names["network"]
  location            = var.location
  security_rules      = local.nsg_rules[each.key]
  tags                = module.tags.tags
}

module "nsg_associations" {
  source                    = "../../modules/terraform-azurerm-compeer-nsg-subnet-association"
  for_each                  = var.subnets
  subnet_id                 = local.subnet_ids[each.key]
  network_security_group_id = module.network_security_groups[each.key].id
}

module "route_tables" {
  source                        = "../../modules/terraform-azurerm-compeer-route-table"
  for_each                      = var.subnets
  name                          = module.naming.route_table_names[each.key]
  resource_group_name           = module.resource_groups.group_names["network"]
  location                      = var.location
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  routes                        = local.routes[each.key]
  tags                          = module.tags.tags
}

module "route_associations" {
  source         = "../../modules/terraform-azurerm-compeer-subnet-route-table-association"
  for_each       = var.subnets
  subnet_id      = local.subnet_ids[each.key]
  route_table_id = module.route_tables[each.key].id
}

module "attachment_naming" {
  source                 = "../../modules/terraform-azurerm-compeer-naming"
  scope                  = "workload"
  region                 = var.location
  environment            = var.environment
  domain                 = var.domain
  appcode                = var.appcode
  private_dns_link_vnets = [module.naming.workload_vnet]
  vnet_peerings = {
    spoke = { local_vnet = module.naming.workload_vnet, remote_vnet = try(split("/", var.platform.hub_virtual_network_id)[8], "hub") }
    hub   = { local_vnet = try(split("/", var.platform.hub_virtual_network_id)[8], "hub"), remote_vnet = module.naming.workload_vnet }
  }
}

module "peering" {
  source = "../terraform-azurerm-compeer-hub-spoke-peering"
  count  = var.manage_hub_attachment ? 1 : 0
  providers = {
    azurerm.hub   = azurerm.connectivity
    azurerm.spoke = azurerm
    azurerm.dns   = azurerm.dns
  }
  tenant_id                   = var.tenant_id
  hub_subscription_id         = data.azurerm_client_config.connectivity.subscription_id
  spoke_subscription_id       = var.subscription_id
  private_dns_subscription_id = data.azurerm_client_config.dns.subscription_id
  hub_virtual_network_id      = var.platform.hub_virtual_network_id
  spoke_virtual_network_id    = module.network.id
  peering_names = {
    hub_to_spoke = module.attachment_naming.vnet_peering_names["hub"]
    spoke_to_hub = module.attachment_naming.vnet_peering_names["spoke"]
  }
  hub_to_spoke = { allow_gateway_transit = var.gateway_transit_enabled }
  spoke_to_hub = { use_remote_gateways = var.gateway_transit_enabled }
  # Zone links are owned once by the parent blueprint, through its DNS alias.
  private_dns_zones = {}
}

module "private_dns_link" {
  source    = "../../modules/terraform-azurerm-compeer-private-dns-vnet-link"
  providers = { azurerm = azurerm.dns }
  links = { for key in ["vault"] : key => {
    name                  = module.attachment_naming.private_dns_link_names[module.naming.workload_vnet]
    resource_group_name   = try(split("/", var.platform.key_vault_private_dns_zone_id)[4], "")
    private_dns_zone_name = "privatelink.vaultcore.azure.net"
    virtual_network_id    = module.network.id
    registration_enabled  = false
    tags                  = module.tags.tags
  } if var.manage_hub_attachment }
  tags       = module.tags.tags
  depends_on = [module.peering]
}

module "workload_identity" {
  source              = "../../modules/terraform-azurerm-compeer-user-assigned-identity"
  name                = module.naming.user_assigned_identity_names["workload"]
  resource_group_name = module.resource_groups.group_names["security"]
  location            = var.location
  tags                = module.tags.tags
}

module "key_vault" {
  source                     = "../terraform-azurerm-compeer-workload-key-vault"
  resource_group_name        = module.resource_groups.group_names["security"]
  location                   = var.location
  tenant_id                  = var.tenant_id
  environment                = var.environment
  appcode                    = var.appcode
  domain                     = var.domain
  name                       = var.key_vault.name
  sku_name                   = var.key_vault.sku_name
  private_endpoint_subnet_id = local.subnet_ids["private_endpoints"]
  private_dns_zone_id        = var.platform.key_vault_private_dns_zone_id
  log_analytics_workspace_id = var.platform.log_analytics_workspace_id
  secret_readers = merge(var.key_vault.secret_readers, {
    workload = { principal_id = module.workload_identity.principal_id, principal_type = "ServicePrincipal" }
  })
  secret_officer_group_ids = var.key_vault.secret_officer_group_ids
  tags                     = module.tags.tags
  depends_on               = [module.nsg_associations, module.route_associations, module.private_dns_link]
}

module "workload_access" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"
  assignments = merge([for scope_key in local.resource_group_keys : {
    for key, assignment in var.workload_access_group_ids : "${scope_key}-${key}" => {
      scope                = module.resource_groups.group_ids[scope_key]
      principal_id         = assignment.principal_id
      principal_type       = "Group"
      role_definition_name = assignment.role
    }
  }]...)
}
