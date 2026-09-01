# Backup policies by workload criticality tier (deploy-runbook.tf §12:
# "policy by workload criticality tier, not ad hoc per VM"). Protected-item
# enrolment stays with the pattern that owns the VM / file share.

resource "azurerm_backup_policy_vm" "this" {
  for_each = var.backup_policy_vm

  name                           = each.value.name
  resource_group_name            = var.resource_group_name
  recovery_vault_name            = azurerm_recovery_services_vault.this.name
  policy_type                    = try(each.value.policy_type, "V2")
  timezone                       = try(each.value.timezone, "UTC")
  instant_restore_retention_days = try(each.value.instant_restore_retention_days, null)

  backup {
    frequency     = each.value.backup.frequency
    time          = each.value.backup.time
    hour_interval = try(each.value.backup.hour_interval, null)
    hour_duration = try(each.value.backup.hour_duration, null)
    weekdays      = try(each.value.backup.weekdays, null)
  }

  dynamic "retention_daily" {
    for_each = try(each.value.retention_daily, null) == null ? [] : [each.value.retention_daily]
    content {
      count = retention_daily.value.count
    }
  }

  dynamic "retention_weekly" {
    for_each = try(each.value.retention_weekly, null) == null ? [] : [each.value.retention_weekly]
    content {
      count    = retention_weekly.value.count
      weekdays = retention_weekly.value.weekdays
    }
  }

  dynamic "retention_monthly" {
    for_each = try(each.value.retention_monthly, null) == null ? [] : [each.value.retention_monthly]
    content {
      count             = retention_monthly.value.count
      weekdays          = try(retention_monthly.value.weekdays, null)
      weeks             = try(retention_monthly.value.weeks, null)
      days              = try(retention_monthly.value.days, null)
      include_last_days = try(retention_monthly.value.include_last_days, null)
    }
  }

  dynamic "retention_yearly" {
    for_each = try(each.value.retention_yearly, null) == null ? [] : [each.value.retention_yearly]
    content {
      count             = retention_yearly.value.count
      months            = retention_yearly.value.months
      weekdays          = try(retention_yearly.value.weekdays, null)
      weeks             = try(retention_yearly.value.weeks, null)
      days              = try(retention_yearly.value.days, null)
      include_last_days = try(retention_yearly.value.include_last_days, null)
    }
  }
}

resource "azurerm_backup_policy_file_share" "this" {
  for_each = var.backup_policy_file_share

  name                = each.value.name
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  timezone            = try(each.value.timezone, "UTC")

  backup {
    frequency = each.value.backup.frequency
    time      = each.value.backup.time
  }

  retention_daily {
    count = each.value.retention_daily.count
  }

  dynamic "retention_weekly" {
    for_each = try(each.value.retention_weekly, null) == null ? [] : [each.value.retention_weekly]
    content {
      count    = retention_weekly.value.count
      weekdays = retention_weekly.value.weekdays
    }
  }

  dynamic "retention_monthly" {
    for_each = try(each.value.retention_monthly, null) == null ? [] : [each.value.retention_monthly]
    content {
      count    = retention_monthly.value.count
      weekdays = retention_monthly.value.weekdays
      weeks    = retention_monthly.value.weeks
    }
  }

  dynamic "retention_yearly" {
    for_each = try(each.value.retention_yearly, null) == null ? [] : [each.value.retention_yearly]
    content {
      count    = retention_yearly.value.count
      weekdays = retention_yearly.value.weekdays
      weeks    = retention_yearly.value.weeks
      months   = retention_yearly.value.months
    }
  }
}
