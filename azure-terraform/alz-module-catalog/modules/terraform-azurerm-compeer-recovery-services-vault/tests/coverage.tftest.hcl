mock_provider "azurerm" {}

variables {
  name                = "rsv-backup"
  resource_group_name = "rg-backup"
  location            = "eastus2"
}

run "outputs_are_wired" {
  command = apply

  assert {
    condition     = output.id == azurerm_recovery_services_vault.vault.id && output.name == azurerm_recovery_services_vault.vault.name
    error_message = "id/name outputs must echo the resource"
  }
  assert {
    condition     = output.identity_principal_id == null && output.identity_tenant_id == null
    error_message = "identity outputs must be null when no identity block is configured"
  }
  assert {
    condition     = length(output.backup_policy_vm_ids) == 0 && length(output.backup_policy_file_share_ids) == 0
    error_message = "backup policy id maps must be empty when no policies are configured"
  }
}

run "identity_dynamic_block_wired_to_outputs" {
  command = apply
  variables {
    identity = { type = "SystemAssigned" }
  }

  assert {
    condition     = output.identity_principal_id == azurerm_recovery_services_vault.vault.identity[0].principal_id
    error_message = "identity_principal_id output must echo the resource's identity block"
  }
  assert {
    condition     = output.identity_tenant_id == azurerm_recovery_services_vault.vault.identity[0].tenant_id
    error_message = "identity_tenant_id output must echo the resource's identity block"
  }
}

run "encryption_dynamic_block_renders" {
  command = plan
  variables {
    identity = { type = "SystemAssigned" }
    encryption = {
      key_id                       = "https://kv.vault.azure.net/keys/rsv-key/version"
      use_system_assigned_identity = true
    }
  }

  assert {
    condition     = azurerm_recovery_services_vault.vault.encryption[0].key_id == "https://kv.vault.azure.net/keys/rsv-key/version"
    error_message = "encryption block should render with the configured key_id"
  }
}

run "monitoring_dynamic_block_renders" {
  command = plan
  variables {
    monitoring = {
      alerts_for_all_job_failures_enabled = false
    }
  }

  assert {
    condition     = azurerm_recovery_services_vault.vault.monitoring[0].alerts_for_all_job_failures_enabled == false
    error_message = "monitoring block should render with the configured override"
  }
}

run "backup_policies_support_multiple_keys_and_wire_ids" {
  # Previously only ever tested with a single "tier0" key - a
  # key-interpolation bug in for_each would not have been caught.
  command = apply
  variables {
    backup_policy_vm = {
      tier0 = {
        name            = "pol-tier0"
        backup          = { frequency = "Daily", time = "22:00" }
        retention_daily = { count = 30 }
      }
      tier1 = {
        name            = "pol-tier1"
        backup          = { frequency = "Daily", time = "23:00" }
        retention_daily = { count = 7 }
      }
    }
    backup_policy_file_share = {
      fs0 = {
        name            = "pol-fs0"
        backup          = { frequency = "Daily", time = "22:00" }
        retention_daily = { count = 30 }
      }
    }
  }

  assert {
    condition     = length(output.backup_policy_vm_ids) == 2 && length(output.backup_policy_file_share_ids) == 1
    error_message = "both VM backup policy keys and the file share policy key should each produce their own output entry"
  }
  assert {
    condition     = output.backup_policy_vm_ids["tier0"] == azurerm_backup_policy_vm.vm_policy["tier0"].id && output.backup_policy_vm_ids["tier1"] == azurerm_backup_policy_vm.vm_policy["tier1"].id
    error_message = "each backup_policy_vm_ids entry must map to the correct policy's id, not a shared/incorrect one"
  }
}
