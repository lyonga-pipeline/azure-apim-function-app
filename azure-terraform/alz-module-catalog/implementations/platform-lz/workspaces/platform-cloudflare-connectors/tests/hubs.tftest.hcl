mock_provider "azurerm" {}
mock_provider "time" {}
mock_provider "tfe" {}

override_data {
  target = data.tfe_outputs.hub["primary"]
  values = { nonsensitive_values = {
    hub_virtual_network_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub-a"
    subnet_ids             = { connectors = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub-a/subnets/connectors" }
  } }
}
override_data {
  target = data.tfe_outputs.hub["secondary"]
  values = { nonsensitive_values = {
    hub_virtual_network_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub-b"
    subnet_ids             = { connectors = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub-b/subnets/connectors" }
  } }
}
variables {
  tenant_id        = "00000000-0000-0000-0000-000000000000"
  subscription_id  = "11111111-1111-1111-1111-111111111111"
  use_tfe_outputs  = true
  tfe_organization = null
  hub_workspaces = {
    primary   = { organization = "Compeer", workspace = "hub-a" }
    secondary = { organization = "Compeer", workspace = "hub-b" }
  }
  phase2_agents   = {}
  admin_passwords = { np01 = "NotAReal!Password2026", prod01 = "NotAReal!Password2026" }
  cloudflare_connectors = {
    enabled = true
    connectors = {
      np01   = { os_type = "Windows", name = "cus-np-cft-01", nic_name = "cus-np-cft-01-nic", hub_key = "primary", subnet_key = "connectors" }
      prod01 = { os_type = "Windows", name = "cus-prod-cft-01", nic_name = "cus-prod-cft-01-nic", hub_key = "secondary", subnet_key = "connectors" }
    }
  }
}
run "hub_ids_come_from_each_selected_producer" {
  command = plan
  assert {
    condition = (endswith(local.connectors["np01"].subnet_id, "/virtualNetworks/hub-a/subnets/connectors") &&
    endswith(local.connectors["prod01"].subnet_id, "/virtualNetworks/hub-b/subnets/connectors"))
    error_message = "Each connector must resolve its own hub's subnet, without hardcoded VNet IDs."
  }
}
run "cross_subscription_nic_attachment_is_rejected" {
  command = plan
  variables { subscription_id = "22222222-2222-2222-2222-222222222222" }
  expect_failures = [terraform_data.hub_contract]
}
run "windows_ama_matches_windows_connector" {
  command = plan
  variables {
    phase2_agent_ownership_confirmed = true
    log_analytics_workspace_id       = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.OperationalInsights/workspaces/law"
    cloudflare_connectors = {
      enabled = true
      connectors = { np01 = {
        os_type  = "Windows", name = "cus-np-cft-01", nic_name = "cus-np-cft-01-nic", hub_key = "primary", subnet_key = "connectors"
        identity = { type = "SystemAssigned, UserAssigned", identity_ids = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ama"] }
      } }
    }
    phase2_agents = { np01 = {
      os_type                    = "Windows", managed_identity_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/identity-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ama"
      identity_and_network_ready = true
      data_collection_rules      = { events = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/monitor-rg/providers/Microsoft.Insights/dataCollectionRules/windows-events" }
    } }
  }
  assert {
    condition     = length(module.phase2_vm_observability[0].agent_ids) == 1
    error_message = "Windows connectors must support Windows AMA through the existing observability owner."
  }
}

run "common_mde_keeps_network_watcher_and_requires_owner" {
  command = plan
  variables {
    mde_extension_ownership_confirmed = false
    cloudflare_connectors = {
      enabled = true
      common_extensions = { mde_windows = {
        name                   = "MDE.Windows", publisher = "Microsoft.Azure.AzureDefenderForServers", type = "MDE.Windows", type_handler_version = "1.0"
        protected_settings_key = "mde"
      } }
      connectors = { np01 = {
        os_type    = "Windows", name = "cus-np-cft-01", nic_name = "cus-np-cft-01-nic", hub_key = "primary", subnet_key = "connectors"
        extensions = { network_watcher = { publisher = "Microsoft.Azure.NetworkWatcher", type = "NetworkWatcherAgentWindows", type_handler_version = "1.4" } }
      } }
    }
    extension_protected_settings = { mde = "{\"defenderForEndpointOnboardingScript\":\"c3ludGhldGljLXRlc3Qtb25seQ==\"}" }
  }
  expect_failures = [terraform_data.hub_contract]
}

run "confirmed_mde_is_merged_with_existing_extensions" {
  command = plan
  variables {
    mde_extension_ownership_confirmed = true
    cloudflare_connectors = {
      enabled = true
      common_extensions = { mde_windows = {
        name                   = "MDE.Windows", publisher = "Microsoft.Azure.AzureDefenderForServers", type = "MDE.Windows", type_handler_version = "1.0"
        protected_settings_key = "mde"
      } }
      connectors = { np01 = {
        os_type    = "Windows", name = "cus-np-cft-01", nic_name = "cus-np-cft-01-nic", hub_key = "primary", subnet_key = "connectors"
        extensions = { network_watcher = { publisher = "Microsoft.Azure.NetworkWatcher", type = "NetworkWatcherAgentWindows", type_handler_version = "1.4" } }
      } }
    }
    extension_protected_settings = { mde = "{\"defenderForEndpointOnboardingScript\":\"c3ludGhldGljLXRlc3Qtb25seQ==\"}" }
  }
  assert {
    condition = (length(local.connectors["np01"].extensions) == 2 &&
      local.connectors["np01"].extensions.mde_windows.type == "MDE.Windows" &&
    local.connectors["np01"].extensions.network_watcher.type == "NetworkWatcherAgentWindows")
    error_message = "Common MDE extension must not overwrite per-VM Network Watcher."
  }
}
