module "sql_server" {
  source                               = "Azure/avm-res-sql-server/azurerm"
  version                              = "0.2.1"
  name                                 = var.name
  location                             = var.location
  resource_group_name                  = var.resource_group_name
  server_version                       = "12.0"
  public_network_access_enabled        = false
  outbound_network_restriction_enabled = true
  managed_identities                   = { system_assigned = true }
  azuread_administrator = {
    login_username              = var.entra_admin_login
    object_id                   = var.entra_admin_object_id
    azuread_authentication_only = true
  }
  private_endpoints = {
    sql = {
      subnet_resource_id            = var.private_endpoint_subnet_id
      subresource_name              = "sqlServer"
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
