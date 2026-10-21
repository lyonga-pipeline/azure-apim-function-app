mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = { subscription_id = "11111111-1111-1111-1111-111111111111", tenant_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" }
  }
  mock_resource "azurerm_resource_group" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/workload" }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/spoke" }
  }
  mock_resource "azurerm_subnet" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/spoke/subnets/fixture" }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/networkSecurityGroups/fixture" }
  }
  mock_resource "azurerm_route_table" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/routeTables/fixture" }
  }
  mock_resource "azurerm_monitor_action_group" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/operations/providers/Microsoft.Insights/actionGroups/workload" }
  }
  mock_resource "azurerm_key_vault" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-prod-security-rg/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault" }
  }
  mock_resource "azurerm_storage_account" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-prod-data-rg/providers/Microsoft.Storage/storageAccounts/exampleordprddb01" }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = { principal_id = "55555555-5555-5555-5555-555555555555" }
  }
  mock_resource "azurerm_application_insights" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/operations/providers/Microsoft.Insights/components/orders-appi" }
  }
}
mock_provider "azurerm" {
  alias = "dns"
  mock_data "azurerm_client_config" {
    defaults = { subscription_id = "33333333-3333-3333-3333-333333333333", tenant_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" }
  }
}

# The regression script supplies baseline.tfvars + EACH real variant, not test-only copies.
run "example_is_disabled_until_approved" {
  command = plan
  assert {
    condition     = output.spoke == null
    error_message = "Reference values must not deploy by default."
  }
}
run "enabled_example_requires_explicit_approval" {
  command = plan
  variables { enabled = true }
  expect_failures = [terraform_data.approval]
}
run "approved_variant_composes_the_real_blueprint" {
  command = apply
  variables {
    enabled             = true
    deployment_approved = true
  }
  assert {
    condition = (
      (output.spoke.key_vault != null) == try(var.key_vault.enabled, true) &&
      toset(keys(output.spoke.application_services.storage)) == toset([for key, account in var.storage_accounts : key if try(account.enabled, true)]) &&
      (output.spoke.application_services.application_insights_id != null) == try(var.monitoring.enabled, false) &&
      (output.spoke.application_services.failed_requests_alert_id != null) == try(var.monitoring.alerts_enabled, false) &&
      length(output.spoke.application_services.created_action_group_ids) == (try(var.operations.create_action_group, false) && try(var.monitoring.alerts_enabled, false) ? 1 : 0) &&
      length(output.spoke.application_services.backup_registration_ids) == (var.backup == null ? 0 : try(var.backup.enabled, true) ? length(var.backup.virtual_machines) : 0) &&
      output.spoke.attachment_contract.owner == "central-attachment-workspace" &&
      output.spoke.environment_profile.tier == (var.environment == "prod" ? "production" : "non-production")
    )
    error_message = "Actual example inputs must honor parent enablement, resource reuse and centralized attachment, not merely parse."
  }
  assert {
    condition = (
      length(output.spoke.diagnostic_ownership.existing_setting_ids) == length(try(var.diagnostics.existing_settings, {})) &&
      length([for target in values(output.spoke.diagnostic_ownership.targets) : target if target.owner == "this-workload-state"]) + length(output.spoke.diagnostic_ownership.existing_setting_ids) == length(output.spoke.diagnostic_ownership.targets)
    )
    error_message = "Every enabled audit target must have exactly one declared owner."
  }
}
