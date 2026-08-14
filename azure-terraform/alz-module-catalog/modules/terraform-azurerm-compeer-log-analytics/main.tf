/**  # Log Analytics
*  
*  Deploys a log analytics workspace for collecting all diagnostics logs and metrics. Can collect logs across multiple subscriptions and connect to Security Center. It is recommended to deploy only one instance per region to collect all diagnostics in one place. For multiple regions it can be advantagious to deploy one in each region, as recommended by Microsoft.
*  
*  ## Setup
*  
*  Not all options are available in terraform yet. To collect Azure Activity logs additional configuration is required after deployment.
*  
*  Open deployed log analytics workspace and go to "Workspace Data Sources" -> "Azure Activity log" and connect to subscriptions that should collect activity logs.
*  
*  ## Usage
*  
*  ```terraform
*  module "log_analytics_workspace" {
*    source = "../"
*  }
*  
*  inputs {
*    log_analytics_workspace_name  = "test-log-analytics"
*    resource_group_name = "rgr-test"
*    log_analytics_role_definition_name = "Log Analytics Contributor"
*    log_analytics_sku = "PerNode"
*    log_analytics_retention_in_days = 30
*  
*    log_analytics_solutions = [
*      {
*        solution_name = "ContainerInsights",
*        publisher     = "Microsoft",
*        product       = "OMSGallery/ContainerInsights",
*      },
*    ]
*  
*    tags = {
*      ProjectName  = "demo-internal"
*      Env          = "dev"
*      Owner        = "user@example.com"
*      BusinessUnit = "CORP"
*    }
*  }
*  ```
*  ## Solutions
*  Some of the solutions that can be added:
*  | solution_name | publisher | product |
*  |---------------|-----------|---------|
*  | ContainerInsights | Microsoft | OMSGallery/ContainerInsights |
*  | AzureAppGatewayAnalytics | Microsoft | OMSGallery/AzureAppGatewayAnalytics |
*  | AzureActivity | Microsoft | OMSGallery/AzureActivity |
*  | Security | Microsoft | OMSGallery/Security |
*  | KeyVaultAnalytics | Microsoft | OMSGallery/KeyVaultAnalytics |
*  | AntiMalware | Microsoft | OMSGallery/AntiMalware |
*  | NetworkMonitoring | Microsoft | OMSGallery/NetworkMonitoring |
*  In addition if using Azure Firewall install the [Azure Firewall sample workspace](https://docs.microsoft.com/en-us/azure/firewall/log-analytics-samples) for viewing firewall logs.
*  ## Contributors
*  If sharing a log analytics instance with other subscriptions it might be required to assign `Log Analytics Contributor` access to other service principals. Use the `contributor` input variable to assign access to other users / apps. This should be a list of object_ids. 
*/