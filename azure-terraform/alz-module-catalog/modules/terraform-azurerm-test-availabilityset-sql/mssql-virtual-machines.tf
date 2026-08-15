resource "azurerm_windows_virtual_machine" "windows_vm" {
  admin_username           = var.admin_username
  admin_password           = var.admin_password
  location                 = var.location
  resource_group_name      = var.resource_group_name
  name                     = var.virtual_machine_name
  network_interface_ids    = [azurerm_network_interface.nic.id]
  size                     = var.virtual_machine_size
  enable_automatic_updates = var.enable_automatic_updates
  #availability_set_id      = var.enable_availability_set ? element(concat(azurerm_availability_set.availability.*.id, [""]), 0) : null
  availability_set_id = var.availability_set_id != null ? var.availability_set_id : (var.enable_availability_set ? element(concat(azurerm_availability_set.availability.*.id, [""]), 0) : null)

  dynamic "os_disk" {
    for_each = var.os_disk != null ? [var.os_disk] : []
    content {
      name                 = os_disk.value.name
      caching              = os_disk.value.caching
      storage_account_type = os_disk.value.storage_account_type
      disk_size_gb         = lookup(os_disk.value, "disk_size_gb", 80)
    }
  }

  dynamic "identity" {
    for_each = var.managed_identity_type != null ? [1] : []
    content {
      type         = var.managed_identity_type
      identity_ids = var.managed_identity_type == "UserAssigned" || var.managed_identity_type == "SystemAssigned, UserAssigned" ? var.managed_identity_ids : null
    }
  }

  dynamic "source_image_reference" {
    for_each = var.source_image_reference != null ? [var.source_image_reference] : []
    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }
  tags = var.tags
}

resource "azurerm_mssql_virtual_machine" "mssql_virtual_machine" {
  depends_on         = [azurerm_windows_virtual_machine.windows_vm, azurerm_virtual_machine_data_disk_attachment.data_disk_attachment]
  virtual_machine_id = azurerm_windows_virtual_machine.windows_vm.id
  sql_license_type   = var.sql_license_type

  dynamic "auto_backup" {
    for_each = var.auto_backup != null ? [var.auto_backup] : []
    content {
      encryption_enabled  = lookup(auto_backup.value, "encryption_enabled", false)
      encryption_password = auto_backup.value.encryption_enabled ? auto_backup.value.encryption_password : null
      dynamic "manual_schedule" {
        for_each = auto_backup.value.manual_schedule != null ? [auto_backup.value.manual_schedule] : []
        content {
          full_backup_frequency           = manual_schedule.value.full_backup_frequency
          full_backup_start_hour          = manual_schedule.value.full_backup_start_hour
          full_backup_window_in_hours     = manual_schedule.value.full_backup_window_in_hours
          log_backup_frequency_in_minutes = manual_schedule.value.log_backup_frequency_in_minutes
          days_of_week                    = manual_schedule.value.full_backup_frequency == "Weekly" ? manual_schedule.value.days_of_week : null
        }
      }
      retention_period_in_days        = auto_backup.value.retention_period_in_days
      storage_blob_endpoint           = auto_backup.value.storage_blob_endpoint
      storage_account_access_key      = auto_backup.value.storage_account_access_key
      system_databases_backup_enabled = lookup(auto_backup.value, "system_databases_backup_enabled", null)
    }
  }

  dynamic "auto_patching" {
    for_each = var.auto_patching != null ? [var.auto_patching] : []
    content {
      day_of_week                            = auto_patching.value.day_of_week
      maintenance_window_starting_hour       = auto_patching.value.maintenance_window_starting_hour
      maintenance_window_duration_in_minutes = auto_patching.value.maintenance_window_duration_in_minutes
    }
  }

  dynamic "key_vault_credential" {
    for_each = var.key_vault_credential != null ? [var.key_vault_credential] : []
    content {
      name                     = key_vault_credential.value.name
      key_vault_url            = key_vault_credential.value.key_vault_url
      service_principal_name   = key_vault_credential.value.service_principal_name
      service_principal_secret = key_vault_credential.value.service_principal_secret
    }
  }

  r_services_enabled               = var.r_services_enabled
  sql_connectivity_port            = var.sql_connectivity_port
  sql_connectivity_type            = var.sql_connectivity_type
  sql_connectivity_update_password = var.sql_connectivity_update_password
  sql_connectivity_update_username = var.sql_connectivity_update_username

  dynamic "sql_instance" {
    for_each = var.sql_instance != null ? [var.sql_instance] : []
    content {
      adhoc_workloads_optimization_enabled = lookup(sql_instance.value, "adhoc_workloads_optimization_enabled", false)
      collation                            = lookup(sql_instance.value, "collation", "SQL_Latin1_General_CP1_CI_AS")
      instant_file_initialization_enabled  = lookup(sql_instance.value, "instant_file_initialization_enabled", false)
      lock_pages_in_memory_enabled         = lookup(sql_instance.value, "lock_pages_in_memory_enabled", false)
      max_dop                              = lookup(sql_instance.value, "max_dop", 0)
      max_server_memory_mb                 = lookup(sql_instance.value, "max_server_memory_mb", 512)
      min_server_memory_mb                 = lookup(sql_instance.value, "min_server_memory_mb", 0)
    }
  }

  dynamic "storage_configuration" {
    for_each = var.storage_configuration != null ? [var.storage_configuration] : []
    content {
      disk_type             = storage_configuration.value.disk_type
      storage_workload_type = storage_configuration.value.storage_workload_type
      dynamic "data_settings" {
        for_each = storage_configuration.value.data_settings != null ? [storage_configuration.value.data_settings] : []
        content {
          default_file_path = data_settings.value.default_file_path
          luns              = data_settings.value.luns
        }
      }
      dynamic "log_settings" {
        for_each = storage_configuration.value.log_settings != null ? [storage_configuration.value.log_settings] : []
        content {
          default_file_path = log_settings.value.default_file_path
          luns              = log_settings.value.luns
        }
      }
      system_db_on_data_disk_enabled = lookup(storage_configuration.value, "system_db_on_data_disk_enabled", false)
      dynamic "temp_db_settings" {
        for_each = storage_configuration.value.temp_db_settings != null ? [storage_configuration.value.temp_db_settings] : []
        content {
          default_file_path      = temp_db_settings.value.default_file_path
          luns                   = temp_db_settings.value.luns
          data_file_count        = lookup(temp_db_settings.value, "data_file_count", 8)
          data_file_size_mb      = lookup(temp_db_settings.value, "data_file_size_mb", 256)
          data_file_growth_in_mb = lookup(temp_db_settings.value, "data_file_growth_in_mb", 512)
          log_file_size_mb       = lookup(temp_db_settings.value, "log_file_size_mb", 256)
          log_file_growth_mb     = lookup(temp_db_settings.value, "log_file_growth_mb", 512)
        }
      }
    }
  }

  dynamic "assessment" {
    for_each = var.assessment != null ? [var.assessment] : []
    content {
      enabled         = lookup(assessment.value, "enabled", true)
      run_immediately = lookup(assessment.value, "run_immediately", false)
      dynamic "schedule" {
        for_each = assessment.value.schedule != null ? [assessment.value.schedule] : []
        content {
          weekly_interval    = schedule.value.monthly_occurrence == null ? schedule.value.weekly_interval : null
          monthly_occurrence = schedule.value.weekly_interval == null ? schedule.value.monthly_occurrence : null
          day_of_week        = lookup(schedule.value, "day_of_week", "Monday")
          start_time         = schedule.value.start_time
        }
      }
    }
  }

  sql_virtual_machine_group_id = var.sql_virtual_machine_group_id

  dynamic "wsfc_domain_credential" {
    for_each = var.wsfc_domain_credential != null ? [var.wsfc_domain_credential] : []
    content {
      cluster_bootstrap_account_password = wsfc_domain_credential.value.cluster_bootstrap_account_password
      cluster_operator_account_password  = wsfc_domain_credential.value.cluster_operator_account_password
      sql_service_account_password       = wsfc_domain_credential.value.sql_service_account_password
    }
  }

}
