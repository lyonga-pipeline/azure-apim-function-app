# Run with exactly one adjacent *.tfvars.example file. All external providers are mocked.
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "11111111-1111-1111-1111-111111111111"
      tenant_id       = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    }
  }
  mock_resource "azurerm_resource_group" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-uat-app-rg" }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-uat-network-rg/providers/Microsoft.Network/virtualNetworks/orders-cus-uat-spoke-vnet" }
  }
  mock_resource "azurerm_subnet" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-uat-network-rg/providers/Microsoft.Network/virtualNetworks/orders-cus-uat-spoke-vnet/subnets/uat-private-endpoints-subnet" }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-uat-network-rg/providers/Microsoft.Network/networkSecurityGroups/application" }
  }
  mock_resource "azurerm_route_table" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-uat-network-rg/providers/Microsoft.Network/routeTables/application" }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = { principal_id = "55555555-5555-5555-5555-555555555555" }
  }
  mock_resource "azurerm_key_vault" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-uat-security-rg/providers/Microsoft.KeyVault/vaults/orders-cus-uat-vault" }
  }
  mock_resource "azurerm_storage_account" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-uat-data-rg/providers/Microsoft.Storage/storageAccounts/exordersuatdata01" }
  }
  mock_resource "azurerm_application_insights" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-uat-operations-rg/providers/Microsoft.Insights/components/orders-cus-uat-appi" }
  }
  mock_resource "azurerm_monitor_action_group" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-uat-operations-rg/providers/Microsoft.Insights/actionGroups/orders-operations" }
  }
}
mock_provider "azurerm" {
  alias = "dns"
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "33333333-3333-3333-3333-333333333333"
      tenant_id       = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    }
  }
}
mock_provider "time" {
  mock_resource "time_static" { defaults = { rfc3339 = "2026-10-26T12:00:00Z" } }
}
mock_provider "tfe" {
  mock_data "tfe_outputs" {
    defaults = {
      nonsensitive_values = {
        contract_version     = "0.1.0"
        mandatory_tag_keys   = ["application", "environment", "owner", "cost_center"]
        action_group_enabled = true
        action_group_ids = {
          primary = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/actionGroups/platform-primary"
        }
        log_analytics_workspace_id        = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
        hub_virtual_network_id            = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
        hub_virtual_network_address_space = ["10.102.0.0/21"]
        key_vault_private_dns_zone_id     = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
        storage_blob_private_dns_zone_id  = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
        dns_server_ips                    = ["10.102.0.10", "10.102.0.11"]
      }
      values = { contract_version = "DO_NOT_READ_SENSITIVE_OUTPUTS" }
    }
  }
}

run "example_is_disabled_without_platform_reads" {
  command = plan
  assert {
    condition = (
      !var.spoke.enabled && var.environment == "uat" && output.spoke == null &&
      length(data.tfe_outputs.management) == 0 && length(data.tfe_outputs.connectivity) == 0 &&
      length(data.tfe_outputs.governance) == 0 && length(time_static.deployment_created) == 0
    )
    error_message = "The checked-in UAT example must remain inert and must not read platform outputs."
  }
}

run "enabled_example_composes_the_pinned_blueprint" {
  command = apply
  variables {
    spoke = merge(var.spoke, { enabled = true })
  }
  assert {
    condition = (
      output.spoke.context.environment == "uat" &&
      output.spoke.environment_profile.tier == "non-production" &&
      output.spoke.environment_profile.alert_severity == 3 &&
      output.spoke.environment_profile.telemetry_sampling_percentage == (var.spoke.monitoring.create_application_insights ? 100 : 20) &&
      output.spoke.application_services.storage.data.replication_type == "ZRS" &&
      output.spoke.application_services.storage.data.delete_retention_days == 30 &&
      toset(keys(output.spoke.application_services.storage)) == toset(["data"]) &&
      output.spoke.security_baseline.key_vault_rbac && output.spoke.security_baseline.key_vault_purge_protection &&
      !output.spoke.security_baseline.key_vault_public_access &&
      output.attachment_contract.owner == "central-attachment-workspace"
    )
    error_message = "The example must preserve UAT isolation, explicit resilient storage, vault security and central attachment ownership."
  }
  assert {
    condition = (
      output.spoke.application_services.application_insights_configuration_managed == var.spoke.monitoring.create_application_insights &&
      output.spoke.application_services.telemetry_access_managed == var.spoke.monitoring.create_application_insights &&
      output.spoke.application_services.application_insights_owner == (var.spoke.monitoring.create_application_insights ? "this-workload-state" : "existing-resource-owner") &&
      output.spoke.application_services.failed_requests_alert_owner == (var.spoke.monitoring.create_failed_requests_alert ? "this-workload-state" : "existing-resource-owner") &&
      length(output.spoke.application_services.created_action_group_ids) == (var.spoke.operations.create_action_group ? 1 : 0) &&
      length(output.spoke.application_services.action_group_ids) == 1 &&
      contains(keys(output.spoke.resource_group_names), "operations") == var.spoke.monitoring.create_application_insights
    )
    error_message = "Create/reuse flags must select the intended owners without duplicate telemetry, contact groups or unused operations RGs."
  }
  assert {
    condition = (
      toset(keys(output.spoke.diagnostic_ownership.targets)) == toset(["key_vault", "storage.data.account", "storage.data.blob"]) &&
      alltrue([for target in values(output.spoke.diagnostic_ownership.targets) : target.owner == (var.spoke.diagnostics.enabled ? "this-workload-state" : "existing-resource-owner")]) &&
      toset(output.spoke.diagnostic_ownership.targets["storage.data.blob"].log_categories) == toset(["StorageRead", "StorageWrite", "StorageDelete"]) &&
      length(output.spoke.diagnostic_ownership.existing_setting_ids) == (var.spoke.diagnostics.enabled ? 0 : 3)
    )
    error_message = "Audit coverage must target the exact vault/account/Blob resources and retain the selected diagnostic owner."
  }
}

run "example_cannot_deploy_production_from_this_root" {
  command = plan
  variables {
    environment = "prod"
  }
  expect_failures = [var.environment]
}
