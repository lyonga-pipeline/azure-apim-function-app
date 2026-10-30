mock_provider "azurerm" {
  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Storage/storageAccounts/compeerarchive"
    }
  }
}
variables { resource_group_name = "monitor-rg" }
run "archive_disabled_by_default" {
  command = plan
  assert {
    condition     = length(module.storage) + length(azurerm_log_analytics_data_export_rule.archive) == 0
    error_message = "No archive/irreversible WORM change without explicit approval."
  }
}
run "approved_archive_exports_selected_tables" {
  command = plan
  variables {
    archive = {
      name                         = "compeerarchive"
      workspace_id                 = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/platform-law"
      workspace_region             = "centralus"
      audit_workspace_id           = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/audit-law"
      private_endpoint_subnet_id   = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/hub/subnets/endpoints"
      private_dns_zone_id          = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
      retention_days               = 365
      retention_approval_reference = "EXAMPLE-NOT-REGULATORY-APPROVAL"
      export_access_approved       = true
      tables                       = ["SecurityEvent"]
      delete_after_days            = 400
    }
  }
  assert {
    condition     = length(module.storage) == 1 && azurerm_log_analytics_data_export_rule.archive["primary"].enabled && length(module.audit) == 1
    error_message = "Archive needs actual export plus audit, not storage alone."
  }
  assert {
    condition     = module.storage["primary"].security_configuration.versioning_enabled && length(module.lifecycle) == 1 && length(module.account_metrics) == 1
    error_message = "WORM needs blob versioning, approved deletion and account metrics."
  }
}
run "audit_reuse_without_recursive_tables_has_no_empty_lifecycle" {
  command = plan
  variables {
    archive = {
      name                         = "compeerarchive"
      workspace_id                 = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/platform-law"
      workspace_region             = "centralus"
      audit_workspace_id           = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/platform-law"
      private_endpoint_subnet_id   = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/hub/subnets/endpoints"
      private_dns_zone_id          = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
      retention_days               = 365
      retention_approval_reference = "MOCK-APPROVAL"
      export_access_approved       = true
      tables                       = ["SecurityEvent"]
    }
  }
  assert {
    condition     = length(module.lifecycle) == 0 && length(module.audit) == 1
    error_message = "Omitted deletion must not create an empty Azure lifecycle policy; audit LAW can be reused safely."
  }
}
run "recursive_audit_export_is_rejected" {
  command = plan
  variables {
    archive = {
      name                         = "compeerarchive"
      workspace_id                 = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/platform-law"
      workspace_region             = "centralus"
      audit_workspace_id           = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/platform-law"
      private_endpoint_subnet_id   = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/hub/subnets/endpoints"
      private_dns_zone_id          = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/dns-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
      retention_days               = 365
      retention_approval_reference = "MOCK-APPROVAL"
      export_access_approved       = true
      tables                       = ["storagebloblogs", "AzureMetrics"]
    }
  }
  expect_failures = [var.archive]
}
run "unapproved_retention_and_lock_rejected" {
  command = plan
  variables {
    archive = {
      name                         = "compeerarchive"
      workspace_id                 = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/platform-law"
      workspace_region             = "centralus"
      audit_workspace_id           = "different"
      private_endpoint_subnet_id   = "invalid"
      private_dns_zone_id          = "invalid"
      retention_days               = 365
      retention_approval_reference = ""
      lock_immutability            = true
      export_access_approved       = false
      tables                       = ["SecurityEvent"]
    }
  }
  expect_failures = [var.archive]
}
