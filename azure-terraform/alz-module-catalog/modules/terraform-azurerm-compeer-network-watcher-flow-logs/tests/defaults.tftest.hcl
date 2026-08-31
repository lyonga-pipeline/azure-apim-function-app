mock_provider "azurerm" {}
variables {
  flow_logs = {
    app-nsg = {
      name                      = "fl-app-nsg"
      network_watcher_name      = "NetworkWatcher_eastus2"
      resource_group_name       = "NetworkWatcherRG"
      network_security_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/networkSecurityGroups/nsg-app"
      storage_account_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/flowlogsa"
    }
  }
}
run "create" {
  command = apply
  assert {
    condition     = azurerm_network_watcher_flow_log.this["app-nsg"].enabled == true
    error_message = "flow log enabled by default"
  }
}
