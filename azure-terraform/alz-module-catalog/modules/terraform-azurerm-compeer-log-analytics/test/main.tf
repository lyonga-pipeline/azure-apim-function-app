provider "azurerm" {
  features {}
}

module "log_analytics_workspace" {
  source = "../"

  log_analytics_workspace_name    = "test-log-analytics"
  resource_group_name             = "rgr-test"
  location                        = "northcentralus"
  log_analytics_sku               = "PerGB2018"
  log_analytics_retention_in_days = 180
  log_analytics_daily_quota_gb    = 10

  tags = {
    env = "dev"
  }
}
