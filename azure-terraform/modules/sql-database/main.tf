resource "azurerm_mssql_database" "this" {
  for_each                       = var.databases
  name                           = each.key
  server_id                      = var.server_id
  sku_name                       = try(each.value.sku_name, "GP_S_Gen5_2")
  max_size_gb                    = try(each.value.max_size_gb, 32)
  zone_redundant                 = try(each.value.zone_redundant, false)
  read_scale                     = try(each.value.read_scale, false)
  collation                      = try(each.value.collation, null)
  license_type                   = try(each.value.license_type, null)
  enclave_type                   = try(each.value.enclave_type, null)
  ledger_enabled                 = try(each.value.ledger_enabled, false)
  elastic_pool_id                = try(each.value.elastic_pool_id, null)
  maintenance_configuration_name = try(each.value.maintenance_configuration_name, null)
  tags                           = merge(var.tags, try(each.value.tags, {}))
}
