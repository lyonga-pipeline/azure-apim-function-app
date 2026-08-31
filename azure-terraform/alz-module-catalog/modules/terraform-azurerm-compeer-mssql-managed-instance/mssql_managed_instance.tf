resource "azurerm_mssql_managed_instance" "mssql_managed_instance" {
  administrator_login            = var.administrator_login
  administrator_login_password   = var.administrator_login_password
  license_type                   = var.license_type
  location                       = var.location
  name                           = var.name
  resource_group_name            = var.resource_group_name
  sku_name                       = var.sku_name
  storage_size_in_gb             = var.storage_size_in_gb
  subnet_id                      = var.subnet_id
  vcores                         = var.vcores
  collation                      = var.collation
  dns_zone_partner_id            = var.dns_zone_partner_id
  maintenance_configuration_name = var.maintenance_configuration_name
  minimum_tls_version            = var.minimum_tls_version
  proxy_override                 = var.proxy_override
  public_data_endpoint_enabled   = var.public_data_endpoint_enabled
  storage_account_type           = var.storage_account_type
  tags                           = var.tags
  timezone_id                    = var.timezone_id

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }
}