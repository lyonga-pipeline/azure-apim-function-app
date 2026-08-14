# Azurerm provider configuration
provider "azurerm" {
  features {}
}

module "vnet" {
  source = "../"

  # By default, this module will not create a resource group, proivde the name here
  # to use an existing resource group, specify the existing resource group name,
  # and set the argument to `create_resource_group = true`. Location will be same as existing RG.

  create_resource_group  = true
  resource_group_name    = "rgr-test"
  vnetwork_name          = "vnet-test"
  location               = "eastus2"
  vnet_address_space     = ["10.1.0.0/16"]
  create_network_watcher = false

  # Adding Standard DDoS Plan, and custom DNS servers (Optional)
  create_ddos_plan = false
  ddos_plan_name   = "ddosplantest01"

  # Multiple Subnets, Service delegation, Service Endpoints, Network security groups
  # These are default subnets with required configuration, check README.md for more details
  # NSG association to be added automatically for all subnets listed here.
  # Subnet name will be set as per Azure naming convention by defaut. expected value here is: <App or project name>

  subnets = {
    mgnt_subnet = {
      subnet_name           = "snet-management"
      subnet_address_prefix = ["10.1.2.0/24"]

      delegation = {
        name = "testdelegation"
        service_delegation = {
          name    = "Microsoft.ContainerInstance/containerGroups"
          actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
        }
      }

      nsg_inbound_rules = [
        {
          name                       = "AllowWebIn"
          priority                   = 200
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "8080"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowWebIn2"
          priority                   = 201
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]

      nsg_outbound_rules = [
        {
          name                       = "ntp_out"
          priority                   = 220
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Udp"
          source_port_range          = "*"
          destination_port_range     = "123"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }

    pvt_subnet = {
      subnet_name           = "snet-pvt"
      subnet_address_prefix = ["10.1.4.0/24"]
      service_endpoints     = ["Microsoft.Storage"]
    }
  }

  # Adding TAG's to your Azure resources (Required)
  tags = {
    ProjectName  = "demo-internal"
    Env          = "dev"
    Owner        = "user@example.com"
    BusinessUnit = "CORP"
    ServiceClass = "Gold"
  }
}