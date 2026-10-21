# Existing same-subscription VMs ONLY. This enrolls them, not creates a VM, vault or policy.
# Platform/application owner must approve policy retention, region and restore testing first.
environment      = "prod"
key_vault        = { enabled = true, sku_name = "standard" }
diagnostics      = { enabled = true, existing_settings = {} }
monitoring       = { enabled = false, alerts_enabled = false }
operations       = { create_action_group = false }
storage_accounts = {}
backup = {
  enabled           = true
  recovery_vault_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/recovery/providers/Microsoft.RecoveryServices/vaults/workload-rsv"
  backup_policy_id  = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/recovery/providers/Microsoft.RecoveryServices/vaults/workload-rsv/backupPolicies/approved-gold"
  virtual_machines = {
    app01 = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/application/providers/Microsoft.Compute/virtualMachines/app01"
  }
}
