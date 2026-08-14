provider "azurerm" {
  features {}
}

module "service_bus" {
  source = "../"
  name                          = "sb-02-namespace"
  resource_group_name           = "rgr-test"
  sku                           = "Standard"
  public_network_access_enabled = true
  firewall_ip_rules = ["1.1.1.1", "2.2.2.2"] 
  
  queues = [
    {
      name = "queue_test"
      enable_partitioning = false
      authorization_rules = [
        {
          name   = "listen-example"
          rights = ["listen"]
        },
        {
          name   = "send-example"
          rights = ["send"]
        },
      ]
    }
  ]

  topics = [
    {
      name                       = "topic_test"
      enable_partitioning        = true
      authorization_rules = [
        {
          name   = "example"
          rights = ["listen", "send"]
        }
      ]
      subscriptions = [
        {
          name                                 = "sub_test"
          max_delivery_count                   = 1
          lock_duration                        = "PT5M" //ISO 8601 format
          forward_to                           = ""
        }
      ]
    }
  ]

  tags = {
    ProjectName  = "demo-internal"
    Env          = "dev"
    Owner        = "user@example.com"
    BusinessUnit = "CORP"
  }
}
