# Azurerm provider configuration
provider "azurerm" {
  features {}
}

# Defining Data Blocks

data "azurerm_resource_group" "rg" {
  name = "rgr-test"
}

data "azurerm_virtual_network" "vnet" {
  name                = "vnet-test"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "snet" {
  name                 = "snet-management"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

module "route_table" {
  source              = "../"
  subnet_id           = data.azurerm_subnet.snet.id
  route_table_name    = "ncus-tst-pan-rt"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "northcentralus"
  routes = [
    { name = "DefaultRoute", address_prefix = "0.0.0.0/0", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.100.185.75" },
    { name = "HubvNET", address_prefix = "10.100.184.0/21", next_hop_type = "VirtualAppliance", next_hop_in_ip_address = "10.100.185.75" },
  ]
  disable_bgp_route_propagation = false
}