mock_provider "azurerm" {}

variables {
  name                = "rsv-backup"
  resource_group_name = "rg-backup"
  location            = "eastus2"
}

run "accepts_valid_sku_storage_mode_immutability_identity" {
  command = plan

  variables {
    sku               = "RS0"
    storage_mode_type = "ZoneRedundant"
    immutability      = "Locked"
    identity          = { type = "SystemAssigned, UserAssigned" }
  }

  assert {
    condition     = azurerm_recovery_services_vault.vault.sku == "RS0"
    error_message = "valid sku should be accepted"
  }
}

run "rejects_bad_sku" {
  command = plan
  variables {
    sku = "Basic"
  }
  expect_failures = [var.sku]
}

run "rejects_bad_storage_mode_type" {
  command = plan
  variables {
    storage_mode_type = "SuperRedundant"
  }
  expect_failures = [var.storage_mode_type]
}

run "rejects_bad_immutability" {
  command = plan
  variables {
    immutability = "Enabled"
  }
  expect_failures = [var.immutability]
}

run "rejects_bad_identity_type" {
  command = plan
  variables {
    identity = { type = "Legacy" }
  }
  expect_failures = [var.identity]
}

run "accepts_valid_vm_backup_policy" {
  command = plan
  variables {
    backup_policy_vm = {
      tier0 = {
        name        = "pol-tier0"
        policy_type = "V2"
        backup = {
          frequency     = "Hourly"
          time          = "22:00"
          hour_interval = 4
          hour_duration = 12
        }
        instant_restore_retention_days = 30
        retention_daily                = { count = 30 }
        retention_weekly               = { count = 12, weekdays = ["Sunday"] }
        retention_monthly              = { count = 12, weekdays = ["Sunday"], weeks = ["First"] }
        retention_yearly               = { count = 5, months = ["January"], weekdays = ["Sunday"], weeks = ["First"] }
      }
    }
  }
  assert {
    condition     = azurerm_backup_policy_vm.vm_policy["tier0"].name == "pol-tier0"
    error_message = "valid VM backup policy should be accepted"
  }
}

run "rejects_bad_vm_policy_type" {
  command = plan
  variables {
    backup_policy_vm = {
      tier0 = {
        name            = "pol-tier0"
        policy_type     = "V3"
        backup          = { frequency = "Daily", time = "22:00" }
        retention_daily = { count = 30 }
      }
    }
  }
  expect_failures = [var.backup_policy_vm]
}

run "rejects_bad_vm_backup_frequency" {
  command = plan
  variables {
    backup_policy_vm = {
      tier0 = {
        name   = "pol-tier0"
        backup = { frequency = "Monthly", time = "22:00" }
      }
    }
  }
  expect_failures = [var.backup_policy_vm]
}

run "rejects_bad_hour_interval" {
  command = plan
  variables {
    backup_policy_vm = {
      tier0 = {
        name   = "pol-tier0"
        backup = { frequency = "Hourly", time = "22:00", hour_interval = 5, hour_duration = 12 }
      }
    }
  }
  expect_failures = [var.backup_policy_vm]
}

run "rejects_retention_daily_below_minimum" {
  command = plan
  variables {
    backup_policy_vm = {
      tier0 = {
        name            = "pol-tier0"
        backup          = { frequency = "Daily", time = "22:00" }
        retention_daily = { count = 3 } # below the documented 7-day minimum
      }
    }
  }
  expect_failures = [var.backup_policy_vm]
}

run "rejects_instant_restore_retention_days_out_of_range_for_v1" {
  command = plan
  variables {
    backup_policy_vm = {
      tier0 = {
        name                           = "pol-tier0"
        policy_type                    = "V1"
        instant_restore_retention_days = 10 # V1 max is 5
        backup                         = { frequency = "Daily", time = "22:00" }
        retention_daily                = { count = 30 }
      }
    }
  }
  expect_failures = [var.backup_policy_vm]
}

run "accepts_valid_file_share_backup_policy" {
  command = plan
  variables {
    backup_policy_file_share = {
      tier0 = {
        name            = "pol-fs-tier0"
        backup          = { frequency = "Daily", time = "22:00" }
        retention_daily = { count = 30 }
      }
    }
  }
  assert {
    condition     = azurerm_backup_policy_file_share.file_share_policy["tier0"].name == "pol-fs-tier0"
    error_message = "valid file share backup policy should be accepted"
  }
}

run "rejects_bad_file_share_backup_frequency" {
  command = plan
  variables {
    backup_policy_file_share = {
      tier0 = {
        name            = "pol-fs-tier0"
        backup          = { frequency = "Weekly", time = "22:00" } # not supported for file share
        retention_daily = { count = 30 }
      }
    }
  }
  expect_failures = [var.backup_policy_file_share]
}

run "rejects_file_share_retention_daily_over_maximum" {
  command = plan
  variables {
    backup_policy_file_share = {
      tier0 = {
        name            = "pol-fs-tier0"
        backup          = { frequency = "Daily", time = "22:00" }
        retention_daily = { count = 201 } # max is 200
      }
    }
  }
  expect_failures = [var.backup_policy_file_share]
}

run "rejects_file_share_retention_yearly_over_maximum" {
  command = plan
  variables {
    backup_policy_file_share = {
      tier0 = {
        name             = "pol-fs-tier0"
        backup           = { frequency = "Daily", time = "22:00" }
        retention_daily  = { count = 30 }
        retention_yearly = { count = 11, weekdays = ["Sunday"], weeks = ["First"], months = ["January"] } # max is 10
      }
    }
  }
  expect_failures = [var.backup_policy_file_share]
}
