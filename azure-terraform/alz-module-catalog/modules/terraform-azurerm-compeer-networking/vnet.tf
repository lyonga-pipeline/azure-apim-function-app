#------------------------
# Local declarations
#------------------------
locals {
  resource_group_name = element(coalescelist(data.azurerm_resource_group.rgrp.*.name, azurerm_resource_group.rg.*.name, [""]), 0)
  location            = element(coalescelist(data.azurerm_resource_group.rgrp.*.location, azurerm_resource_group.rg.*.location, [""]), 0)
  if_ddos_enabled     = var.create_ddos_plan ? [{}] : []
}

data "azurerm_resource_group" "rgrp" {
  count = var.create_resource_group == false ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

#-----------------------
# VNET Creation
#-----------------------

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnetwork_name
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = var.vnet_address_space
  tags                = merge({ "Name" = format("%s", var.vnetwork_name) }, var.tags, )

  dynamic "ddos_protection_plan" {
    for_each = local.if_ddos_enabled

    content {
      id     = azurerm_network_ddos_protection_plan.ddos[0].id
      enable = true
    }
  }
}

#--------------------------------------------
# Ddos protection plan - Default is "false"
#--------------------------------------------

resource "azurerm_network_ddos_protection_plan" "ddos" {
  count               = var.create_ddos_plan ? 1 : 0
  name                = var.ddos_plan_name
  resource_group_name = local.resource_group_name
  location            = local.location
  tags                = var.tags
}

#-------------------------------------
# Network Watcher - Default is "true"
#-------------------------------------
resource "azurerm_resource_group" "nwatcher" {
  count    = var.create_network_watcher != false ? 1 : 0
  name     = "NetworkWatcherRG"
  location = local.location
  tags     = var.tags
}

resource "azurerm_network_watcher" "nwatcher" {
  count               = var.create_network_watcher != false ? 1 : 0
  name                = "NetworkWatcher_${local.location}"
  location            = local.location
  resource_group_name = azurerm_resource_group.nwatcher.0.name
  tags                = var.tags
}

#--------------------------------------------------------------------------------------------------------
# Subnets Creation with Private link endpoint/Service network policies, service endpoints and Delegation.
#--------------------------------------------------------------------------------------------------------

resource "azurerm_subnet" "subnet" {
  for_each                                      = var.subnets
  name                                          = each.value.subnet_name
  resource_group_name                           = local.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  address_prefixes                              = each.value.subnet_address_prefix
  service_endpoints                             = lookup(each.value, "service_endpoints", [])
  service_endpoint_policy_ids                   = lookup(each.value, "service_endpoint_policy_ids", null)
  private_endpoint_network_policies             = lookup(each.value, "private_endpoint_network_policies",  "Enabled") 
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", null)
  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

#-----------------------------------------------
# Network security group - Default is "false"
#-----------------------------------------------

resource "azurerm_network_security_group" "nsg" {
  for_each            = var.subnets
  name                = each.value.nsg_name
  resource_group_name = local.resource_group_name
  location            = local.location
  tags                = var.tags
  dynamic "security_rule" {
    for_each = concat(
      lookup(each.value, "nsg_inbound_rules", []) != null ? lookup(each.value, "nsg_inbound_rules", []) : [],
      lookup(each.value, "nsg_outbound_rules", []) != null ? lookup(each.value, "nsg_outbound_rules", []) : []
    )

    content {
      name                         = security_rule.value["name"]
      priority                     = security_rule.value["priority"]
      direction                    = security_rule.value["direction"]
      access                       = security_rule.value["access"]
      protocol                     = security_rule.value["protocol"]
      source_port_range            = security_rule.value["source_port_range"]
      destination_port_range       = security_rule.value["destination_port_range"]
      source_address_prefix        = security_rule.value["source_address_prefix"]
      source_address_prefixes      = security_rule.value["source_address_prefixes"]
      destination_address_prefix   = security_rule.value["destination_address_prefix"]
      destination_address_prefixes = security_rule.value["destination_address_prefixes"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-assoc" {
  for_each                  = var.subnets
  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

#-----------------------------------------------
# Azure DNS server settings
#-----------------------------------------------
resource "azurerm_virtual_network_dns_servers" "dns" {
  virtual_network_id = azurerm_virtual_network.vnet.id
  dns_servers        = var.dns_servers
}