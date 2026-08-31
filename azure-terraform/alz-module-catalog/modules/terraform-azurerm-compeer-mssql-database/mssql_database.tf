resource "azurerm_mssql_database" "mssql_database" {
  name      = var.name
  server_id = var.server_id

  auto_pause_delay_in_minutes         = var.auto_pause_delay_in_minutes
  create_mode                         = var.create_mode
  creation_source_database_id         = var.creation_source_database_id
  collation                           = var.collation
  elastic_pool_id                     = var.elastic_pool_id
  geo_backup_enabled                  = var.geo_backup_enabled
  maintenance_configuration_name      = var.maintenance_configuration_name
  ledger_enabled                      = var.ledger_enabled
  license_type                        = var.license_type
  max_size_gb                         = var.max_size_gb
  min_capacity                        = var.min_capacity
  restore_point_in_time               = var.restore_point_in_time
  recover_database_id                 = var.recover_database_id
  restore_dropped_database_id         = var.restore_dropped_database_id
  read_replica_count                  = var.read_replica_count
  read_scale                          = var.read_scale
  sample_name                         = var.sample_name
  sku_name                            = var.sku_name
  storage_account_type                = var.storage_account_type
  transparent_data_encryption_enabled = var.transparent_data_encryption_enabled
  zone_redundant                      = var.zone_redundant
  tags                                = var.tags

  dynamic "import" {
    for_each = var.import != null ? [var.import] : []
    content {
      storage_uri                  = import.value.storage_uri
      storage_key                  = import.value.storage_key
      storage_key_type             = import.value.storage_key_type
      administrator_login          = import.value.administrator_login
      administrator_login_password = import.value.administrator_login_password
      authentication_type          = import.value.authentication_type
      storage_account_id           = lookup(import.value, "storage_account_id", null)
    }
  }
  dynamic "long_term_retention_policy" {
    for_each = var.long_term_retention_policy != null ? [var.long_term_retention_policy] : []
    content {
      weekly_retention  = lookup(long_term_retention_policy.value, "weekly_retention", null)
      monthly_retention = lookup(long_term_retention_policy.value, "monthly_retention", null)
      yearly_retention  = lookup(long_term_retention_policy.value, "yearly_retention", null)
      week_of_year      = lookup(long_term_retention_policy.value, "week_of_year", null)
    }
  }
  dynamic "short_term_retention_policy" {
    for_each = var.short_term_retention_policy != null ? [var.short_term_retention_policy] : []
    content {
      retention_days           = short_term_retention_policy.value.retention_days
      backup_interval_in_hours = lookup(short_term_retention_policy.value, "backup_interval_in_hours", 12)
    }
  }
  dynamic "threat_detection_policy" {
    for_each = var.threat_detection_policy != null ? [var.threat_detection_policy] : []
    content {
      state                      = lookup(threat_detection_policy.value, "state", null)
      disabled_alerts            = lookup(threat_detection_policy.value, "disabled_alerts", null)
      email_account_admins       = lookup(threat_detection_policy.value, "email_account_admins", null)
      email_addresses            = lookup(threat_detection_policy.value, "email_addresses", null)
      retention_days             = lookup(threat_detection_policy.value, "retention_days", null)
      storage_account_access_key = lookup(threat_detection_policy.value, "storage_account_access_key", null)
      storage_endpoint           = lookup(threat_detection_policy.value, "storage_endpoint", null)
    }
  }
}