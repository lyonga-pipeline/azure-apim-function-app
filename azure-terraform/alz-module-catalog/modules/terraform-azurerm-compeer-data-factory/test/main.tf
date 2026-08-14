provider "azurerm" {
  features {}
}

module "data_factory" {
  source = "../"

  resource_group_name             = "rgr-test"
  location                        = "northcentralus"
  data_factory_name               = "datafactorynametest01"
  managed_virtual_network_enabled = true
  public_network_enabled          = false
  integration_runtime_custom_name = "AzureIntegrationRuntime01"
  integration_runtime_type        = "Azure"

  tags = {
    env = "dev"
  }
}
