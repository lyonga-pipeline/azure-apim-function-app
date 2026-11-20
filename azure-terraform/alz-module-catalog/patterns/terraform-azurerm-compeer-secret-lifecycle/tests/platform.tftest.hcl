mock_provider "azurerm" {
  mock_resource "azurerm_storage_account" {
    defaults = {
      id                    = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rotation-rg/providers/Microsoft.Storage/storageAccounts/mockstore"
      primary_blob_endpoint = "https://mockstore.blob.core.windows.net/"
    }
  }
  mock_resource "azurerm_servicebus_namespace" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rotation-rg/providers/Microsoft.ServiceBus/namespaces/mockbus" }
  }
  mock_resource "azurerm_servicebus_queue" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rotation-rg/providers/Microsoft.ServiceBus/namespaces/mockbus/queues/work" }
  }
  mock_resource "azurerm_linux_function_app" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rotation-rg/providers/Microsoft.Web/sites/mockapp" }
  }
  mock_resource "azurerm_application_insights" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rotation-rg/providers/Microsoft.Insights/components/mockai" }
  }
  mock_resource "azurerm_service_plan" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rotation-rg/providers/Microsoft.Web/serverFarms/mockplan" }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/rotation-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mockmi"
      client_id    = "00000000-0000-0000-0000-000000000002"
      principal_id = "00000000-0000-0000-0000-000000000003"
    }
  }
}
variables {
  environment                = "nonprod"
  location                   = "centralus"
  tenant_id                  = "00000000-0000-0000-0000-000000000001"
  resource_group_name        = "rotation-rg"
  names                      = { worker = "rotation-worker", scheduler = "rotation-scheduler", plan = "rotation-plan", host_storage = "rotationhost", state_storage = "rotationstate", service_bus = "rotationbus" }
  integration_subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/network/subnets/integration"
  private_endpoint_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/network/subnets/endpoints"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/management-rg/providers/Microsoft.OperationalInsights/workspaces/logs"
  action_group_ids           = ["/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/management-rg/providers/Microsoft.Insights/actionGroups/ops"]
  manual_api_client_id       = "00000000-0000-0000-0000-000000000004"
  operator_group_ids         = ["00000000-0000-0000-0000-000000000005"]
  consumer_hosts             = ["consumer.example.internal"]
  dns_owned_by_policy        = true
}
run "private_scheduler_only_baseline" {
  command = plan
  assert {
    condition     = !azurerm_servicebus_namespace.rotation.public_network_access_enabled && !azurerm_storage_account.state.public_network_access_enabled && !azurerm_storage_account.host.shared_access_key_enabled
    error_message = "Scheduler-only mode must not open public messaging/storage or enable access keys."
  }
  assert {
    condition     = length(azurerm_linux_function_app.app) == 2 && length(azurerm_private_endpoint.rotation) == 7
    error_message = "Separate workers/scheduler and all private endpoints are required."
  }
  assert {
    condition     = azurerm_role_assignment.metadata["scheduler"].role_definition_name == "Storage Blob Data Reader" && length(azurerm_role_assignment.vault) == 0
    error_message = "Scheduler must have no secret permission; no unregistered vault receives rotation access."
  }
}
run "approved_event_exception_is_explicit" {
  command = plan
  variables { event_delivery_exception_approved = true }
  assert {
    condition     = azurerm_servicebus_namespace.rotation.public_network_access_enabled && azurerm_servicebus_namespace.rotation.network_rule_set[0].default_action == "Deny" && azurerm_servicebus_namespace.rotation.network_rule_set[0].trusted_services_allowed
    error_message = "Event mode must preserve default-deny with trusted delivery enabled."
  }
}
run "runtime_package_is_deployed_to_both_apps" {
  command = plan
  variables { package_path = "runtime/host.json" }
  assert {
    condition     = length(terraform_data.code) == 2 && terraform_data.code["worker"].triggers_replace[0] == filesha256("runtime/host.json")
    error_message = "Package changes must redeploy both worker and scheduler."
  }
}
run "reject_cross_environment" {
  command = plan
  variables { environment = "sandbox" }
  expect_failures = [var.environment]
}
run "reject_missing_dns_ownership" {
  command = plan
  variables { dns_owned_by_policy = false }
  expect_failures = [terraform_data.contract]
}
run "reject_shared_integration_and_endpoint_subnet" {
  command = plan
  variables {
    private_endpoint_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/network-rg/providers/Microsoft.Network/virtualNetworks/network/subnets/integration"
  }
  expect_failures = [terraform_data.contract]
}
run "reject_unregistered_vault" {
  command = plan
  variables {
    assets = {
      app = {
        environment = "nonprod", vault_id = "/unregistered", vault_url = "https://vault.vault.azure.net", secret_name = "app-secret", adapter = "entra_application"
        target      = { resource_id = "00000000-0000-0000-0000-000000000001" }
        owner       = "owner", support_group = "ops", approval_reference = "CHG1", recovery_reference = "runbook", adapter_approved = false, consumer_inventory_reviewed = false
        initial_due = "2027-01-01T00:00:00Z"
        consumers   = [{ name = "app", refresh_url = "https://consumer.example.internal/refresh", validate_url = "https://consumer.example.internal/validate", audience = "api://consumer" }]
      }
    }
  }
  expect_failures = [terraform_data.contract]
}
