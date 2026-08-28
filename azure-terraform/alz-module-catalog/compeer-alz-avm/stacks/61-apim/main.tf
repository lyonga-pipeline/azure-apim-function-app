module "apim" {
  source                        = "Azure/avm-res-apimanagement-service/azurerm"
  version                       = "0.9.0"
  name                          = "cmp-prod-cus-apim"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  publisher_email               = var.publisher_email
  publisher_name                = var.publisher_name
  sku_name                      = var.sku_name
  min_api_version               = "2021-08-01"
  public_network_access_enabled = false
  virtual_network_type          = "None"
  private_endpoints = {
    gateway = {
      subnet_resource_id            = var.private_endpoint_subnet_id
      subresource_name              = "Gateway"
      private_dns_zone_resource_ids = var.private_dns_zone_ids
      lock                          = { kind = "CanNotDelete" }
      tags                          = var.tags
    }
  }
  diagnostic_settings = { law = { workspace_resource_id = var.log_analytics_workspace_id } }
  lock                = { kind = "CanNotDelete" }
  tags                = merge({ ManagedBy = "Terraform", IaCSource = "AVM", Phase = "2" }, var.tags)
  enable_telemetry    = var.enable_telemetry
}
