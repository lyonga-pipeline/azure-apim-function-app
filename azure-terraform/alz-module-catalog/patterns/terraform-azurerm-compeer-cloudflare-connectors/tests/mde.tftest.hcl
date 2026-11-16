mock_provider "azurerm" {}
variables {
  subscription_id = "11111111-1111-1111-1111-111111111111"
  location        = "centralus"
  environment     = "prod"
  resource_group  = { name = "platform-cus-prod-cfc-rg" }
  admin_passwords = { np01 = "NotAReal!Password2026" }
  connectors = { np01 = {
    os_type   = "Windows", name = "cus-np-cft-01", nic_name = "cus-np-cft-01-nic"
    subnet_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub/subnets/connectors"
    extensions = {
      network_watcher = { publisher = "Microsoft.Azure.NetworkWatcher", type = "NetworkWatcherAgentWindows", type_handler_version = "1.4" }
      mde_windows = {
        name     = "MDE.Windows", publisher = "Microsoft.Azure.AzureDefenderForServers", type = "MDE.Windows", type_handler_version = "1.0"
        settings = { vNextEnabled = "true", installedBy = "Terraform" }, protected_settings_key = "mde"
      }
    }
  } }
  extension_protected_settings = {
    mde = "{\"defenderForEndpointOnboardingScript\":\"c3ludGhldGljLXRlc3Qtb25seQ==\"}"
  }
}

run "mde_and_network_watcher_are_separate_resources" {
  command = plan
  assert {
    condition = (length(azurerm_virtual_machine_extension.extension) == 2 &&
      azurerm_virtual_machine_extension.extension["np01:mde_windows"].name == "MDE.Windows" &&
      azurerm_virtual_machine_extension.extension["np01:mde_windows"].publisher == "Microsoft.Azure.AzureDefenderForServers" &&
    azurerm_virtual_machine_extension.extension["np01:network_watcher"].type == "NetworkWatcherAgentWindows")
    error_message = "MDE and Network Watcher must have independent resource identities."
  }
}
run "mde_missing_onboarding_package_is_rejected" {
  command = plan
  variables { extension_protected_settings = {} }
  expect_failures = [azurerm_virtual_machine_extension.extension["np01:mde_windows"]]
}
run "mde_invalid_base64_is_rejected" {
  command = plan
  variables { extension_protected_settings = { mde = "{\"defenderForEndpointOnboardingScript\":\"not-base64\"}" } }
  expect_failures = [azurerm_virtual_machine_extension.extension["np01:mde_windows"]]
}
run "mde_without_sensitive_json_is_rejected" {
  command = plan
  variables { extension_protected_settings = { mde = "not-json" } }
  expect_failures = [azurerm_virtual_machine_extension.extension["np01:mde_windows"]]
}
run "mde_rejects_empty_package" {
  command = plan
  variables {
    extension_protected_settings = { mde = "{\"defenderForEndpointOnboardingScript\":\"\"}" }
  }
  expect_failures = [azurerm_virtual_machine_extension.extension["np01:mde_windows"]]
}
