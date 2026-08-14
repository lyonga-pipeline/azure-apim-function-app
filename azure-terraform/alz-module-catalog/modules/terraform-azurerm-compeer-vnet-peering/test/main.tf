provider "azurerm" {
  features {}
  alias           = "hub"
  subscription_id = var.hub_subscription_id
}

provider "azurerm" {
  features {}
  alias           = "spoke"
  subscription_id = var.spoke_subscription_id
}

# Defining Data Blocks

data "azurerm_resource_group" "hub-rg" {
  provider = azurerm.hub
  name     = var.hub_rg_name
}

data "azurerm_virtual_network" "hub-vnet" {
  provider = azurerm.hub
  name = var.hub_vnet_name
  resource_group_name = data.azurerm_resource_group.hub-rg.name
}

data "azurerm_resource_group" "spoke-rg" {
  provider = azurerm.spoke
  name     = var.spoke_rg_name
}

data "azurerm_virtual_network" "spoke-vnet" {
  provider            = azurerm.spoke
  name                = var.spoke_vnet_name
  resource_group_name = data.azurerm_resource_group.spoke-rg.name
}

module "spoke_to_hub_peering" {
  source = "../"
  providers = {
    azurerm = azurerm.hub
  }
  peering_name              = "ncus-dev-to-hub-cn"
  rg_name               = data.azurerm_resource_group.hub-rg.name
  vnet_name             = data.azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.spoke-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

module "hub_to_spoke_peering" {
  source = "../"
  providers = {
    azurerm = azurerm.spoke
  }
  peering_name              = "ncus-hub-to-dev-cn"
  rg_name               = data.azurerm_resource_group.spoke-rg.name
  vnet_name             = data.azurerm_virtual_network.spoke-vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.hub-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}


