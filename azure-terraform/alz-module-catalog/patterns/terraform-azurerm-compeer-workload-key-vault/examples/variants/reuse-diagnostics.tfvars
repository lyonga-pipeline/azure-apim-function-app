# No duplicate setting: this declaration references, but does not import/update,
# an existing setting for the EXACT vault name/LAW defined in baseline.tfvars.
diagnostics = {
  enabled = false
  existing_setting = {
    id                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-prod-security-rg/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault/providers/Microsoft.Insights/diagnosticSettings/platform-owned"
    workspace_id      = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
    log_categories    = ["AuditEvent"]
    metric_categories = ["AllMetrics"]
  }
}
