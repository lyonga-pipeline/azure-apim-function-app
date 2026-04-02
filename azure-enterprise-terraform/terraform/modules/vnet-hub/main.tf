locals {
  subnet_defaults = {
    address_prefixes                              = []
    service_endpoints                             = []
    private_endpoint_network_policies             = null
    private_endpoint_network_policies_enabled     = true
    enforce_private_link_service_network_policies = true
    private_link_service_network_policies_enabled = true
    route_table_id                                = null
    nat_gateway_id                                = null
    nsg_rules                                     = []
    delegations                                   = []
  }

  default_subnets = tomap({
    AzureFirewallSubnet = merge(local.subnet_defaults, {
      address_prefixes = [var.firewall_subnet_cidr]
    })
    AzureBastionSubnet = merge(local.subnet_defaults, {
      address_prefixes = [var.bastion_subnet_cidr]
    })
    shared-services = merge(local.subnet_defaults, {
      address_prefixes = [var.shared_services_subnet_cidr]
      nsg_rules        = var.shared_services_nsg_rules
    })
    private-endpoints = merge(local.subnet_defaults, {
      address_prefixes                          = [var.private_endpoints_subnet_cidr]
      private_endpoint_network_policies         = "Disabled"
      private_endpoint_network_policies_enabled = false
    })
    dns-inbound = merge(local.subnet_defaults, {
      address_prefixes = [var.dns_inbound_subnet_cidr]
    })
    dns-outbound = merge(local.subnet_defaults, {
      address_prefixes = [var.dns_outbound_subnet_cidr]
    })
  })

  selected_subnets = length(var.subnets) == 0 ? local.default_subnets : tomap(var.subnets)

  effective_subnets = tomap({
    for subnet_name, subnet in local.selected_subnets :
    subnet_name => merge(
      local.subnet_defaults,
      subnet,
      {
        service_endpoints = try(subnet.service_endpoints, [])
        nsg_rules         = try(subnet.nsg_rules, [])
        delegations       = try(subnet.delegations, [])
      }
    )
  })

  firewall_network_rule_collections_by_name = {
    for collection in var.firewall_network_rule_collections : collection.name => collection
  }

  nat_gateway_subnet_ids = [
    for subnet_key in var.nat_gateway_subnet_keys : module.network.subnet_ids[subnet_key]
  ]
}

module "network" {
  source                  = "../network"
  name                    = var.name
  resource_group_name     = var.resource_group_name
  location                = var.location
  address_space           = var.address_space
  dns_servers             = var.dns_servers
  ddos_protection_plan_id = var.ddos_protection_plan_id
  subnets                 = local.effective_subnets
  tags                    = var.tags
}

resource "azurerm_public_ip" "firewall" {
  count               = var.enable_firewall ? 1 : 0
  name                = "${var.name}-fw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy" "this" {
  count                    = var.enable_firewall ? 1 : 0
  name                     = coalesce(var.firewall_policy_name, "${var.name}-fw-policy")
  resource_group_name      = var.resource_group_name
  location                 = var.location
  sku                      = var.firewall_sku_tier
  threat_intelligence_mode = var.firewall_threat_intelligence_mode
  tags                     = var.tags
}

resource "azurerm_firewall" "this" {
  count               = var.enable_firewall ? 1 : 0
  name                = "${var.name}-fw"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.this[0].id
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = module.network.subnet_ids["AzureFirewallSubnet"]
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "this" {
  count              = var.enable_firewall && length(var.firewall_network_rule_collections) > 0 ? 1 : 0
  name               = var.firewall_policy_rule_collection_group_name
  firewall_policy_id = azurerm_firewall_policy.this[0].id
  priority           = var.firewall_policy_rule_collection_group_priority

  dynamic "network_rule_collection" {
    for_each = local.firewall_network_rule_collections_by_name

    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules

        content {
          name                  = rule.value.name
          protocols             = rule.value.protocols
          source_addresses      = rule.value.source_addresses
          destination_ports     = rule.value.destination_ports
          destination_addresses = try(rule.value.destination_addresses, null)
          destination_fqdns     = try(rule.value.destination_fqdns, null)
        }
      }
    }
  }
}

module "nat_gateway" {
  count                   = var.enable_nat_gateway ? 1 : 0
  source                  = "../nat-gateway"
  name                    = coalesce(var.nat_gateway_name, "${var.name}-nat")
  resource_group_name     = var.resource_group_name
  location                = var.location
  subnet_ids              = local.nat_gateway_subnet_ids
  create_public_ip        = var.nat_gateway_create_public_ip
  idle_timeout_in_minutes = var.nat_gateway_idle_timeout_in_minutes
  zones                   = var.nat_gateway_zones
  tags                    = var.tags
}

module "bastion" {
  count                  = var.enable_bastion ? 1 : 0
  source                 = "../bastion"
  name                   = coalesce(var.bastion_name, "${var.name}-bas")
  resource_group_name    = var.resource_group_name
  location               = var.location
  bastion_subnet_id      = module.network.subnet_ids["AzureBastionSubnet"]
  sku                    = var.bastion_sku
  copy_paste_enabled     = var.bastion_copy_paste_enabled
  file_copy_enabled      = var.bastion_file_copy_enabled
  ip_connect_enabled     = var.bastion_ip_connect_enabled
  shareable_link_enabled = var.bastion_shareable_link_enabled
  tunneling_enabled      = var.bastion_tunneling_enabled
  scale_units            = var.bastion_scale_units
  tags                   = var.tags
}

output "vnet_id" {
  value = module.network.vnet_id
}

output "vnet_name" {
  value = module.network.vnet_name
}

output "subnet_ids" {
  value = module.network.subnet_ids
}

output "firewall_private_ip" {
  value = var.enable_firewall ? azurerm_firewall.this[0].ip_configuration[0].private_ip_address : null
}

output "firewall_policy_id" {
  value = var.enable_firewall ? azurerm_firewall_policy.this[0].id : null
}

output "firewall_public_ip" {
  value = var.enable_firewall ? azurerm_public_ip.firewall[0].ip_address : null
}

output "nat_gateway_id" {
  value = var.enable_nat_gateway ? module.nat_gateway[0].id : null
}

output "nat_gateway_public_ip" {
  value = var.enable_nat_gateway ? module.nat_gateway[0].public_ip_address : null
}

output "bastion_id" {
  value = var.enable_bastion ? module.bastion[0].id : null
}

output "bastion_public_ip" {
  value = var.enable_bastion ? module.bastion[0].public_ip_address : null
}
