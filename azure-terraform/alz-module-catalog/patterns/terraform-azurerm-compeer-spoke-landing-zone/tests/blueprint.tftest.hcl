run "rejects_external_blob_diagnostics_on_another_account" {
  command = plan
  override_module {
    target  = module.storage["data"]
    outputs = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/data/providers/Microsoft.Storage/storageAccounts/ordersdatacusprod", name = "ordersdatacusprod" }
  }
  variables {
    key_vault        = { enabled = false }
    storage_accounts = { data = {} }
    diagnostics = {
      existing_settings = {
        "storage.data.blob" = {
          id                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/data/providers/Microsoft.Storage/storageAccounts/otheraccount/blobServices/default/providers/Microsoft.Insights/diagnosticSettings/external"
          workspace_id      = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
          log_categories    = ["StorageRead", "StorageWrite", "StorageDelete"]
          metric_categories = ["Transaction"]
        }
      }
    }
  }
  expect_failures = [terraform_data.reuse_contract]
}

run "rejects_alert_reuse_without_an_existing_rule" {
  command = plan
  variables {
    monitoring = { enabled = true, create_application_insights = true, alerts_enabled = true, create_failed_requests_alert = false }
    operations = {}
  }
  expect_failures = [var.monitoring]
}

run "disabled_vault_needs_no_vault_dns_reference" {
  command = apply
  variables {
    key_vault  = { "enabled" = false }
    monitoring = { "enabled" = false }
    operations = {}
    platform   = { "management_contract_version" = "0.1.0", "connectivity_contract_version" = "0.1.0", "log_analytics_workspace_id" = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law", "hub_virtual_network_id" = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub", "hub_address_space" = ["10.102.0.0/21"], "dns_server_ips" = ["10.102.0.10"] }
  }
  assert {
    condition     = output.key_vault == null && length(output.attachment_contract.private_dns_zones) == 0
    error_message = "Capability switches must remove dependent resources without weakening enabled resources."
  }
}

run "mixed_storage_flags_filter_every_dependent_module" {
  command = apply
  variables {
    storage_accounts = { "data" = { "enabled" = true }, "unused" = { "enabled" = false, "replication_type" = "LRS", "delete_retention_days" = 7, "grant_workload_blob_access" = true } }
  }
  assert {
    condition     = toset(keys(module.storage)) == toset(["data"]) && toset(keys(module.storage_endpoints)) == toset(["data"]) && toset(keys(module.storage_metrics)) == toset(["data"]) && length(module.storage_access.ids) == 0
    error_message = "Capability switches must remove dependent resources without weakening enabled resources."
  }
}

run "rejects_diagnostic_keys_for_disabled_resources" {
  command = plan
  variables {
    key_vault   = { "enabled" = false }
    diagnostics = { "existing_settings" = { "storage.absent.account" = { "id" = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/data/providers/Microsoft.Storage/storageAccounts/ordersdatacusprod/providers/Microsoft.Insights/diagnosticSettings/external", "workspace_id" = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law", "metric_categories" = ["AllMetrics"] } } }
  }
  expect_failures = [terraform_data.capability_contract]
}

run "rejects_diagnostics_to_another_workspace" {
  command = plan
  variables {
    key_vault        = { "enabled" = false }
    storage_accounts = { "data" = {} }
    diagnostics      = { "existing_settings" = { "storage.data.account" = { "id" = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/data/providers/Microsoft.Storage/storageAccounts/ordersdatacusprod/providers/Microsoft.Insights/diagnosticSettings/external", "workspace_id" = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law-wrong", "metric_categories" = ["AllMetrics"] } } }
  }
  expect_failures = [terraform_data.capability_contract]
}

run "rejects_external_blob_auditing_without_write_delete_categories" {
  command = plan
  variables {
    key_vault        = { "enabled" = false }
    storage_accounts = { "data" = {} }
    diagnostics      = { "existing_settings" = { "storage.data.blob" = { "id" = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/data/providers/Microsoft.Storage/storageAccounts/ordersdatacusprod/blobServices/default/providers/Microsoft.Insights/diagnosticSettings/external", "workspace_id" = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law", "log_categories" = ["StorageRead"], "metric_categories" = ["Transaction"] } } }
  }
  expect_failures = [terraform_data.capability_contract]
}

run "rejects_alert_for_another_application_component" {
  command = plan
  variables {
    operations = {}
    monitoring = { "enabled" = true, "create_failed_requests_alert" = false, "alerts_enabled" = true, "existing_application_insights" = { "id" = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/components/orders", "workspace_id" = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law" }, "existing_failed_requests_alert" = { "id" = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/metricAlerts/failures", "application_insights_id" = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/components/orders-wrong", "action_group_ids" = ["/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/actionGroups/operations"] } }
  }
  expect_failures = [terraform_data.reuse_contract]
}

run "rejects_creation_and_reuse_of_one_alert" {
  command = plan
  variables {
    operations = { "action_group_ids" = ["/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/actionGroups/operations"] }
    monitoring = { "enabled" = true, "create_application_insights" = true, "alerts_enabled" = true, "create_failed_requests_alert" = true, "existing_failed_requests_alert" = { "id" = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/metricAlerts/failures", "application_insights_id" = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/components/orders-wrong", "action_group_ids" = ["/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/actionGroups/operations"] } }
  }
  expect_failures = [var.monitoring]
}

mock_provider "azurerm" {
  mock_resource "azurerm_private_endpoint" {
    defaults = {
      private_dns_zone_configs = [{
        name                = "vault"
        id                  = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.Network/privateEndpoints/vault/privateDnsZoneGroups/default/privateDnsZoneConfigs/vault"
        private_dns_zone_id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
        record_sets         = []
      }]
    }
  }
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
  mock_resource "azurerm_key_vault" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault", vault_uri = "https://orders-cus-prod-vault.vault.azure.net/" }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = { principal_id = "55555555-5555-5555-5555-555555555555" }
  }
  mock_resource "azurerm_application_insights" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/operations/providers/Microsoft.Insights/components/orders-appi" }
  }
  mock_resource "azurerm_monitor_action_group" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/operations/providers/Microsoft.Insights/actionGroups/workload" }
  }
  mock_resource "azurerm_storage_account" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/data/providers/Microsoft.Storage/storageAccounts/ordersdatacusprod" }
  }
}

run "vault_opt_out_removes_vault_roles_endpoint_and_zone_intent" {
  command = apply
  variables {
    key_vault        = { enabled = false }
    monitoring       = { enabled = false }
    operations       = {}
    diagnostics      = { enabled = false }
    storage_accounts = { unused = { enabled = false, grant_workload_blob_access = true } }
  }
  assert {
    condition = (
      output.key_vault == null && length(module.key_vault) == 0 &&
      length(module.storage) == 0 && length(module.storage_endpoints) == 0 && length(module.storage_access.ids) == 0 &&
      length(module.storage_metrics) == 0 && length(module.storage_blob_diagnostics) == 0 &&
      output.attachment_contract.key_vault_private_dns_zone_id == null && length(output.attachment_contract.private_dns_zones) == 0 &&
      length(output.diagnostic_ownership.targets) == 0 &&
      toset(keys(output.resource_group_names)) == toset(["network", "security", "application"])
    )
    error_message = "Disabled resources must not leave behind data/operations RGs, endpoints, data-plane roles, diagnostics or central DNS requests."
  }
}

run "diagnostics_off_cannot_leave_enabled_storage_unlogged" {
  command = plan
  variables {
    diagnostics      = { enabled = false }
    key_vault        = { enabled = false }
    storage_accounts = { data = {} }
  }
  expect_failures = [terraform_data.capability_contract]
}

run "reuse_vault_diagnostics_without_second_setting" {
  command = apply
  variables {
    diagnostics = {
      enabled = false
      existing_settings = {
        key_vault = {
          id                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault/providers/Microsoft.Insights/diagnosticSettings/external-audit"
          workspace_id      = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
          log_categories    = ["AuditEvent"]
          metric_categories = ["AllMetrics"]
        }
      }
    }
  }
  assert {
    condition     = length(output.diagnostic_ownership.terraform_resource_ids) == 0 && output.diagnostic_ownership.targets.key_vault.owner == "existing-resource-owner"
    error_message = "Referencing external audit coverage must not create another setting or claim Terraform diagnostic ownership."
  }
}

run "reuse_storage_diagnostics_only_on_correct_child_targets" {
  command = apply
  variables {
    key_vault        = { enabled = false }
    storage_accounts = { data = { enabled = true } }
    diagnostics = {
      enabled = false
      existing_settings = {
        "storage.data.account" = {
          id                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/data/providers/Microsoft.Storage/storageAccounts/ordersdatacusprod/providers/Microsoft.Insights/diagnosticSettings/external-metrics"
          workspace_id      = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
          metric_categories = ["AllMetrics"]
        }
        "storage.data.blob" = {
          id                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/data/providers/Microsoft.Storage/storageAccounts/ordersdatacusprod/blobServices/default/providers/Microsoft.Insights/diagnosticSettings/external-blob"
          workspace_id      = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
          log_categories    = ["StorageRead", "StorageWrite", "StorageDelete"]
          metric_categories = ["Transaction"]
        }
      }
    }
  }
  assert {
    condition     = length(module.storage_metrics) == 0 && length(module.storage_blob_diagnostics) == 0 && length(output.diagnostic_ownership.existing_setting_ids) == 2
    error_message = "External storage diagnostics must cover root metrics and Blob logs without duplicate settings."
  }
}

run "reuse_entire_observability_stack_without_local_resources" {
  command = apply
  variables {
    operations = {}
    monitoring = {
      enabled                     = true
      create_application_insights = false
      existing_application_insights = {
        id           = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/components/approved-application"
        workspace_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
      }
      alerts_enabled               = true
      create_failed_requests_alert = false
      existing_failed_requests_alert = {
        id                      = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/metricAlerts/application-failures"
        application_insights_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/components/approved-application"
        action_group_ids        = ["/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/actionGroups/operations"]
      }
    }
  }
  assert {
    condition = (
      length(module.application_insights) == 0 && length(module.failed_requests_alert) == 0 && length(module.alert_contacts) == 0 &&
      length(module.telemetry_access.ids) == 0 && !contains(keys(output.resource_group_names), "operations") &&
      output.application_services.failed_requests_alert_id == var.monitoring.existing_failed_requests_alert.id &&
      output.application_services.failed_requests_alert_owner == "existing-resource-owner" && length(output.application_services.action_group_ids) == 1
    )
    error_message = "Full reuse must publish existing references, never configure, duplicate or grant access to externally owned telemetry/alerts."
  }
}

run "backup_false_retains_config_without_enrollment" {
  command = apply
  variables {
    backup = { enabled = false, recovery_vault_id = "ON_HOLD", backup_policy_id = "ON_HOLD", virtual_machines = {} }
  }
  assert {
    condition     = length(azurerm_backup_protected_vm.workload) == 0
    error_message = "Disabled backup must not enroll a VM or require active backup IDs."
  }
}
mock_provider "azurerm" {
  alias = "connectivity"
  mock_data "azurerm_client_config" {
    defaults = { subscription_id = "22222222-2222-2222-2222-222222222222", tenant_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" }
  }
}
mock_provider "azurerm" {
  alias = "dns"
  mock_data "azurerm_client_config" {
    defaults = { subscription_id = "33333333-3333-3333-3333-333333333333", tenant_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" }
  }
}

variables {
  subscription_id = "11111111-1111-1111-1111-111111111111"
  tenant_id       = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  location        = "centralus"
  environment     = "prod"
  appcode         = "orders"
  address_space   = ["10.200.0.0/20"]
  subnets = {
    app               = { address_prefixes = ["10.200.0.0/24"] }
    private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
  }
  egress_next_hop_ip = "10.102.0.4"
  # Explicitly exercise the opt-in Phase 2 extensions in this shared fixture.
  monitoring = { enabled = true, create_application_insights = true, alerts_enabled = true }
  operations = {
    create_action_group = true
    notification_emails = ["workload-ops@example.com"]
  }
  workload_tags = {
    application      = "orders", owner = "Applications", source_repo = "ado://Compeer/workloads", created_on = "2026-10-13",
    criticality_tier = "tier-2", data_classification = "confidential", lifecycle_state = "active", cost_center = "CC-0000",
    gl_category      = "cloud-infrastructure", dr_tier = "silver"
  }
  platform = {
    management_contract_version      = "0.1.0"
    connectivity_contract_version    = "0.1.0"
    log_analytics_workspace_id       = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
    hub_virtual_network_id           = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
    hub_address_space                = ["10.102.0.0/21"]
    key_vault_private_dns_zone_id    = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    storage_blob_private_dns_zone_id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    dns_server_ips                   = ["10.102.0.10", "10.102.0.11"]
  }
}

# PHASE2 NEW: sandbox is additive; the default fixture remains unchanged production.
run "sandbox_preserves_security_and_publishes_expiry" {
  command = plan
  variables {
    environment = "sandbox"
    workload_tags = {
      application      = "orders", owner = "Applications", source_repo = "ado://example/sandbox", created_on = "2026-10-13",
      criticality_tier = "tier-2", data_classification = "confidential", lifecycle_state = "active", cost_center = "CC-0000",
      gl_category      = "cloud-infrastructure", dr_tier = "silver", expiration_date = "2027-01-13"
    }
  }
  assert {
    condition     = module.tags.tags.expiration_date == "2027-01-13" && length(module.key_vault) == 1 && length(module.network_security_groups) == 2
    error_message = "Sandbox must reuse the inspected, audited baseline and carry caller-owned expiry."
  }
}
run "sandbox_without_expiry_is_rejected" {
  command = plan
  variables { environment = "sandbox" }
  expect_failures = [var.workload_tags]
}
run "legacy_naming_interface_preserves_appendix_f_names" {
  command = plan
  assert {
    condition = (
      module.naming.resource_group_names.network == "internal-apps-orders-cus-prod-network-rg" &&
      output.resource_group_names.network == "orders-cus-prod-network-rg" &&
      output.resource_group_names.application == "orders-cus-prod-app-rg"
    )
    error_message = "Legacy naming outputs must be adapted without changing approved blueprint RG names."
  }
}

run "canonical_naming_outputs_are_not_stripped_twice" {
  command = plan
  override_module {
    target = module.naming
    outputs = {
      workload_vnet                = "orders-cus-prod-spoke-vnet"
      resource_group_names         = { network = "orders-cus-prod-network-rg", security = "orders-cus-prod-security-rg", app = "orders-cus-prod-app-rg", operations = "orders-cus-prod-operations-rg" }
      subnet_names                 = { app = "prod-app-subnet", private_endpoints = "prod-private-endpoints-subnet" }
      nsg_names                    = { app = "cus-prod-app-nsg", private_endpoints = "cus-prod-private-endpoints-nsg" }
      route_table_names            = { app = "cus-prod-app-rt", private_endpoints = "cus-prod-private-endpoints-rt" }
      user_assigned_identity_names = { workload = "orders-cus-prod-workload-id" }
      storage_account_names        = {}
    }
  }
  assert {
    condition     = output.resource_group_names.network == "orders-cus-prod-network-rg" && output.resource_group_names.application == "orders-cus-prod-app-rg"
    error_message = "An already canonical module output must remain unchanged."
  }
}

run "domain_equal_to_appcode_does_not_remove_the_application_token" {
  command = plan
  variables { domain = "orders" }
  assert {
    condition     = output.resource_group_names.network == "orders-cus-prod-network-rg" && output.resource_group_names.application == "orders-cus-prod-app-rg"
    error_message = "Only a complete legacy domain plus workload prefix may be normalized."
  }
}

run "reuse_explicit_action_group_without_local_contacts" {
  command = apply
  variables {
    operations = { action_group_ids = ["/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/actionGroups/operations"] }
  }
  assert {
    condition = (
      length(module.alert_contacts) == 0 && length(output.application_services.created_action_group_ids) == 0 &&
      output.application_services.action_group_ids == tolist(var.operations.action_group_ids) &&
      one(local.action_group_ids) == one(var.operations.action_group_ids)
    )
    error_message = "An approved existing action group must be referenced, never recreated or assigned new recipients."
  }
}

run "reuse_platform_action_group_by_contract_key" {
  command = apply
  variables {
    operations = { platform_action_group_keys = ["primary"] }
    platform = {
      management_contract_version   = "0.1.0", connectivity_contract_version = "0.1.0"
      log_analytics_workspace_id    = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
      hub_virtual_network_id        = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
      hub_address_space             = ["10.102.0.0/21"], dns_server_ips = ["10.102.0.10"]
      key_vault_private_dns_zone_id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      action_group_ids              = { primary = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/actionGroups/platform" }
    }
  }
  assert {
    condition     = length(module.alert_contacts) == 0 && one(output.application_services.action_group_ids) == var.platform.action_group_ids.primary
    error_message = "Management's named public action-group output must route alerts without a duplicate workload group."
  }
}

run "missing_platform_group_never_falls_back_to_creation" {
  command = plan
  variables { operations = { platform_action_group_keys = ["not-published"] } }
  expect_failures = [terraform_data.capability_contract]
}

run "emails_alone_never_authorize_group_creation" {
  command = plan
  variables { operations = { notification_emails = ["ops@example.com"] } }
  expect_failures = [var.operations]
}

run "no_notification_resources_without_a_consumer" {
  command = apply
  variables {
    monitoring = { enabled = true, create_application_insights = true }
    operations = { create_action_group = true, notification_emails = ["ops@example.com"] }
  }
  assert {
    condition     = length(module.alert_contacts) == 0 && length(module.failed_requests_alert) == 0 && length(output.application_services.action_group_ids) == 0
    error_message = "Telemetry alone must not create an unused action group or alert."
  }
}

run "reuse_existing_application_component_without_taking_ownership" {
  command = apply
  variables {
    operations = {}
    monitoring = {
      enabled = true
      existing_application_insights = {
        id           = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/components/approved-application"
        workspace_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
      }
    }
  }
  assert {
    condition = (
      length(module.application_insights) == 0 && length(module.telemetry_access.ids) == 0 &&
      !contains(keys(output.resource_group_names), "operations") &&
      output.application_services.application_insights_id == var.monitoring.existing_application_insights.id &&
      output.application_services.application_insights_name == "approved-application" &&
      output.application_services.application_insights_owner == "existing-resource-owner" &&
      !output.application_services.application_insights_configuration_managed && !output.application_services.telemetry_access_managed
    )
    error_message = "Reuse must not create a second component, empty operations RG or unapproved role assignment."
  }
}

run "reuse_component_with_explicitly_delegated_identity_access" {
  command = apply
  variables {
    operations = {}
    monitoring = {
      enabled                          = true
      manage_existing_telemetry_access = true
      existing_application_insights = {
        id           = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/components/approved-application"
        workspace_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
      }
    }
  }
  assert {
    condition     = length(module.application_insights) == 0 && module.telemetry_access.assignments.workload.scope == var.monitoring.existing_application_insights.id && output.application_services.telemetry_access_managed
    error_message = "Explicitly delegated access must target only the existing component, without managing its lifecycle."
  }
}

run "rejects_telemetry_without_an_explicit_resource_decision" {
  command = plan
  variables { monitoring = { enabled = true } }
  expect_failures = [var.monitoring]
}

run "rejects_workspace_id_used_as_telemetry_component" {
  command = plan
  variables {
    monitoring = {
      enabled = true
      existing_application_insights = {
        id           = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
        workspace_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
      }
    }
  }
  expect_failures = [var.monitoring]
}

run "rejects_create_and_reuse_of_same_component" {
  command = plan
  variables {
    monitoring = {
      enabled = true, create_application_insights = true
      existing_application_insights = {
        id           = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/components/approved-application"
        workspace_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
      }
    }
  }
  expect_failures = [var.monitoring]
}

run "rejects_reuse_against_a_different_workspace" {
  command = plan
  variables {
    monitoring = {
      enabled = true
      existing_application_insights = {
        id           = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/components/approved-application"
        workspace_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/wrong-law"
      }
    }
  }
  expect_failures = [terraform_data.capability_contract]
}

run "legacy_augmented_rules_reuse_catalog_nsg_without_weakening_baseline" {
  command = apply
  variables {
    subnets = {
      app = {
        address_prefixes = ["10.200.0.0/24"]
        rules = {
          private-web = {
            protocol = "Tcp", destination_port_ranges = ["443", "8443"], source_address_prefix = "10.102.0.0/21", destination_address_prefix = "*",
            access   = "Allow", priority = 300, direction = "Inbound"
          }
          app-to-data = {
            protocol                                   = "Tcp", source_port_ranges = ["1024-65535"], destination_port_ranges = ["1433", "5432"],
            source_application_security_group_ids      = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/application/providers/Microsoft.Network/applicationSecurityGroups/app"],
            destination_application_security_group_ids = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/application/providers/Microsoft.Network/applicationSecurityGroups/data"],
            access                                     = "Allow", priority = 310, direction = "Outbound"
          }
        }
      }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  assert {
    condition = (
      local.nsg_rules.app.private-web.source_port_range == "*" &&
      local.nsg_rules.app.app-to-data.source_port_range == null &&
      local.nsg_rules.app.app-to-data.source_address_prefix == null &&
      toset(local.nsg_rules.app.app-to-data.destination_port_ranges) == toset(["1433", "5432"]) &&
      anytrue([for rule in module.network_security_groups.app.network_security_group_rules : rule.name == "app-to-data" && rule.source_application_security_group_ids == var.subnets.app.rules.app-to-data.source_application_security_group_ids && rule.destination_application_security_group_ids == var.subnets.app.rules.app-to-data.destination_application_security_group_ids && rule.source_port_ranges == toset(["1024-65535"])]) &&
      local.nsg_rules.app.baseline-deny-inbound.priority == 4096 && local.nsg_rules.app.baseline-deny-outbound.priority == 4096
    )
    error_message = "Augmented ports/ASGs must reach the real NSG module, keep the old wildcard-source default, and preserve baseline denies."
  }
}

run "legacy_single_port_rules_keep_existing_source_default" {
  command = plan
  variables {
    subnets = {
      app = { address_prefixes = ["10.200.0.0/24"], rules = {
        approved-https = { protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.102.0.0/21", destination_address_prefix = "*", access = "Allow", priority = 300, direction = "Inbound" }
      } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  assert {
    condition     = local.nsg_rules.app.approved-https.source_port_range == "*" && local.nsg_rules.app.approved-https.destination_port_ranges == null
    error_message = "Existing single-port input must not change its Azure rule configuration."
  }
}

run "legacy_scope_selection_limits_groups_to_requested_resource_groups" {
  command = apply
  variables {
    workload_access_group_ids = {
      application = { principal_id = "66666666-6666-6666-6666-666666666666", role = "Contributor", resource_group_keys = ["application"] }
      operations  = { principal_id = "77777777-7777-7777-7777-777777777777", role = "Reader", resource_group_keys = ["operations"] }
    }
  }
  assert {
    condition = (
      toset(keys(local.workload_access_assignments)) == toset(["application-application", "operations-operations"]) &&
      length(module.workload_access.ids) == 2 &&
      local.workload_access_assignments.application-application.role_definition_name == "Contributor" &&
      local.workload_access_assignments.operations-operations.role_definition_name == "Reader"
    )
    error_message = "A selected application/operations grant must not leak into network or security RGs."
  }
}

run "omitted_resource_group_selection_preserves_existing_role_keys" {
  command = plan
  variables {
    workload_access_group_ids = { reader = { principal_id = "66666666-6666-6666-6666-666666666666", role = "Reader" } }
  }
  assert {
    condition     = toset(keys(local.workload_access_assignments)) == toset(["network-reader", "security-reader", "application-reader", "operations-reader"])
    error_message = "Existing access inputs retain their original role addresses and RG selection."
  }
}

run "rejects_unknown_access_resource_group_key" {
  command = plan
  variables {
    workload_access_group_ids = { reader = { principal_id = "66666666-6666-6666-6666-666666666666", role = "Reader", resource_group_keys = ["not-created"] } }
  }
  expect_failures = [terraform_data.contracts]
}

run "rejects_data_access_without_storage_resource_group" {
  command = plan
  variables {
    workload_access_group_ids = { reader = { principal_id = "66666666-6666-6666-6666-666666666666", role = "Reader", resource_group_keys = ["data"] } }
  }
  expect_failures = [terraform_data.contracts]
}

run "rejects_empty_access_selection" {
  command = plan
  variables {
    workload_access_group_ids = { reader = { principal_id = "66666666-6666-6666-6666-666666666666", role = "Reader", resource_group_keys = [] } }
  }
  expect_failures = [terraform_data.contracts]
}

run "does_not_import_legacy_arbitrary_privileged_roles" {
  command = plan
  variables {
    workload_access_group_ids = { admin = { principal_id = "66666666-6666-6666-6666-666666666666", role = "Owner", resource_group_keys = ["application"] } }
  }
  expect_failures = [var.workload_access_group_ids]
}

run "legacy_optional_tag_metadata_uses_existing_tag_validation" {
  command = apply
  variables {
    workload_tags = {
      application      = "orders", owner = "Applications", source_repo = "ado://Compeer/workloads", created_on = "2026-10-13",
      criticality_tier = "tier-2", data_classification = "confidential", lifecycle_state = "active", cost_center = "CC-0000",
      gl_category      = "cloud-infrastructure", dr_tier = "silver", application_component = "API", modified_on = "2026-10-17"
    }
  }
  assert {
    condition = (
      output.context.tags.application_component == "api" && output.context.tags.modified_on == "2026-10-17" &&
      output.context.tags.created_on == "2026-10-13" && output.context.tags.created_by == "Terraform" &&
      module.network.name == "orders-cus-prod-spoke-vnet"
    )
    error_message = "Optional metadata must use the shared tag module without recomputing deployment dates or resource names."
  }
}

run "rejects_two_source_port_forms" {
  command = plan
  variables {
    subnets = {
      app = { address_prefixes = ["10.200.0.0/24"], rules = {
        reviewed = { protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.102.0.0/21", destination_address_prefix = "*", access = "Allow", priority = 300, direction = "Inbound", source_port_range = "*", source_port_ranges = ["1024-65535"] }
      } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [var.subnets]
}

run "rejects_two_destination_port_forms" {
  command = plan
  variables {
    subnets = {
      app = { address_prefixes = ["10.200.0.0/24"], rules = {
        reviewed = { protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.102.0.0/21", destination_address_prefix = "*", access = "Allow", priority = 300, direction = "Inbound", destination_port_ranges = ["443", "8443"] }
      } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [var.subnets]
}

run "rejects_missing_destination_port" {
  command = plan
  variables {
    subnets = {
      app = { address_prefixes = ["10.200.0.0/24"], rules = {
        reviewed = { protocol = "Tcp", source_address_prefix = "10.102.0.0/21", destination_address_prefix = "*", access = "Allow", priority = 300, direction = "Inbound" }
      } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [var.subnets]
}

run "rejects_empty_destination_port_set" {
  command = plan
  variables {
    subnets = {
      app = { address_prefixes = ["10.200.0.0/24"], rules = {
        reviewed = { protocol = "Tcp", source_address_prefix = "10.102.0.0/21", destination_address_prefix = "*", access = "Allow", priority = 300, direction = "Inbound", destination_port_ranges = [] }
      } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [var.subnets]
}

run "rejects_empty_source_prefix_set" {
  command = plan
  variables {
    subnets = {
      app = { address_prefixes = ["10.200.0.0/24"], rules = {
        reviewed = { protocol = "Tcp", destination_port_range = "443", destination_address_prefix = "*", access = "Allow", priority = 300, direction = "Inbound", source_address_prefixes = [] }
      } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [var.subnets]
}

run "rejects_address_and_asg_in_same_source" {
  command = plan
  variables {
    subnets = {
      app = { address_prefixes = ["10.200.0.0/24"], rules = {
        reviewed = { protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.102.0.0/21", destination_address_prefix = "*", access = "Allow", priority = 300, direction = "Inbound", source_application_security_group_ids = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/application/providers/Microsoft.Network/applicationSecurityGroups/app"] }
      } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [var.subnets]
}

run "rejects_foreign_subscription_asg" {
  command = plan
  variables {
    subnets = {
      app = { address_prefixes = ["10.200.0.0/24"], rules = {
        reviewed = { protocol = "Tcp", destination_port_range = "443", destination_address_prefix = "*", access = "Allow", priority = 300, direction = "Inbound", source_application_security_group_ids = ["/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/application/providers/Microsoft.Network/applicationSecurityGroups/app"] }
      } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [terraform_data.contracts]
}

run "rejects_non_asg_arm_id" {
  command = plan
  variables {
    subnets = {
      app = { address_prefixes = ["10.200.0.0/24"], rules = {
        reviewed = { protocol = "Tcp", destination_port_range = "443", destination_address_prefix = "*", access = "Allow", priority = 300, direction = "Inbound", source_application_security_group_ids = ["/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/application/providers/Microsoft.Network/virtualNetworks/not-an-asg"] }
      } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [var.subnets]
}

run "rejects_internet_wide_augmented_rule" {
  command = plan
  variables {
    subnets = {
      app = { address_prefixes = ["10.200.0.0/24"], rules = {
        reviewed = { protocol = "Tcp", destination_address_prefix = "*", access = "Allow", priority = 300, direction = "Inbound", source_address_prefixes = ["10.102.0.0/21", "0.0.0.0/0"], destination_port_ranges = ["443", "8443"] }
      } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [var.subnets]
}

run "production_spoke_composes_real_modules_with_mocked_azure" {
  command = apply
  assert {
    condition = (
      output.contract_version == "1.0.0" &&
      module.network.name == "orders-cus-prod-spoke-vnet" &&
      module.resource_groups.group_names["network"] == "orders-cus-prod-network-rg" &&
      module.resource_groups.group_names["security"] == "orders-cus-prod-security-rg" &&
      toset(keys(output.subnet_ids)) == toset(["app", "private_endpoints"]) &&
      toset(keys(module.network.subnets)) == toset(keys(local.network_subnets)) &&
      alltrue([for subnet in values(local.network_subnets) : !subnet.default_outbound_access_enabled && subnet.private_endpoint_network_policies == "Enabled"])
    )
    error_message = "The blueprint must preserve generated names and subnet output keys, and pass private subnet defaults through the tested network input contract. Live subnet settings require Azure validation."
  }
  assert {
    condition = (
      length(module.network_security_groups) == 2 && length(module.nsg_associations) == 2 && length(module.route_tables) == 2 && length(module.route_associations) == 2 &&
      alltrue([for routes in values(local.routes) : routes.default-egress.next_hop_in_ip_address == var.egress_next_hop_ip && routes.default-egress.next_hop_type == "VirtualAppliance"]) &&
      local.nsg_rules.app.baseline-deny-inbound.access == "Deny" && local.nsg_rules.app.baseline-deny-outbound.access == "Deny"
    )
    error_message = "Every subnet requires enforced NSG/route associations, default-deny NSGs and explicit inspected egress."
  }
  assert {
    condition = (
      output.attachment_contract.owner == "central-attachment-workspace" &&
      output.attachment_contract.hub_virtual_network_id == var.platform.hub_virtual_network_id &&
      output.attachment_contract.spoke_virtual_network_id == output.spoke_virtual_network_id &&
      output.attachment_contract.private_dns_zones.key_vault.resource_group_name == "dns" &&
      !output.attachment_contract.private_dns_zones.key_vault.registration_enabled &&
      !output.attachment_contract.gateway_transit_enabled
    )
    error_message = "The blueprint must publish exact central attachment intent without deploying either peering or a VNet-to-zone link."
  }
  assert {
    condition = (
      !module.key_vault[0].security_configuration.public_network_access_enabled && module.key_vault[0].security_configuration.purge_protection_enabled &&
      module.key_vault[0].role_assignments.reader-workload.principal_id == output.workload_identity.principal_id &&
      module.key_vault[0].role_assignments.reader-workload.scope == output.key_vault.id &&
      module.key_vault[0].role_assignments.reader-workload.role_definition_name == "Key Vault Secrets User" &&
      output.diagnostic_ownership.workspace_id == var.platform.log_analytics_workspace_id &&
      module.resource_groups.group_names.application == "orders-cus-prod-app-rg" &&
      module.application_insights[0].security_configuration.local_authentication_disabled &&
      module.application_insights[0].security_configuration.workspace_id == var.platform.log_analytics_workspace_id
    )
    error_message = "Every spoke requires a private dedicated vault, scoped workload identity, application RG, Entra-authenticated telemetry and central audit logs."
  }
}

run "nonproduction_uses_same_blueprint_without_weaker_controls" {
  command = plan
  variables { environment = "dev" }
  assert {
    condition = (module.network.name == "orders-cus-dev-spoke-vnet" && module.key_vault[0].name == "orders-cus-dev-vault" &&
      module.key_vault[0].security_configuration.purge_protection_enabled && !module.key_vault[0].security_configuration.public_network_access_enabled
    )
    error_message = "Non-production must change environment naming, not security guarantees."
  }
}

run "external_attachment_has_no_second_owner" {
  command = plan
  variables { manage_hub_attachment = false }
  assert {
    condition = (
      output.attachment_contract.owner == "central-attachment-workspace" &&
      output.attachment_contract.contract_version == "2.0.0" &&
      !contains(keys(output.attachment_contract), "peering_names") &&
      !contains(keys(output.attachment_contract.private_dns_zones.key_vault), "link_name") &&
      output.attachment_contract.naming_context.environment == var.environment &&
      toset(keys(output.attachment_contract.private_dns_zones)) == toset(["key_vault"])
    )
    error_message = "Central attachment mode must not create either peering direction or duplicate the central DNS link."
  }
}

run "gateway_transit_is_an_explicit_paired_decision" {
  command = plan
  variables { gateway_transit_enabled = true }
  assert {
    condition = (
      output.attachment_contract.gateway_transit_enabled &&
      output.attachment_contract.naming_context.appcode == var.appcode &&
      !contains(keys(output.attachment_contract), "peering_names")
    )
    error_message = "Gateway intent and workload context must be published for central approval/naming, not applied or named by the spoke."
  }
}

run "rejects_hub_address_overlap" {
  command = plan
  variables { address_space = ["10.102.0.0/16"] }
  expect_failures = [terraform_data.contracts]
}

run "rejects_overlapping_subnets" {
  command = plan
  variables { subnets = { app = { address_prefixes = ["10.200.0.0/24"] }, private_endpoints = { address_prefixes = ["10.200.0.128/27"] } } }
  expect_failures = [terraform_data.contracts]
}

run "rejects_subnet_outside_vnet" {
  command = plan
  variables { subnets = { app = { address_prefixes = ["10.201.0.0/24"] }, private_endpoints = { address_prefixes = ["10.200.1.0/27"] } } }
  expect_failures = [terraform_data.contracts]
}

run "rejects_reserved_ipam_overlap" {
  command = plan
  variables { reserved_address_spaces = ["10.200.0.0/16"] }
  expect_failures = [terraform_data.contracts]
}

run "rejects_unapproved_egress_target" {
  command = plan
  variables { egress_next_hop_ip = "192.0.2.10" }
  expect_failures = [terraform_data.contracts]
}

run "rejects_missing_private_endpoint_subnet" {
  command = plan
  variables { subnets = { app = { address_prefixes = ["10.200.0.0/24"] } } }
  expect_failures = [var.subnets]
}

run "rejects_internet_wide_inbound" {
  command = plan
  variables {
    subnets = {
      app = { address_prefixes = ["10.200.0.0/24"], rules = {
        unsafe = { protocol = "Tcp", destination_port_range = "443", source_address_prefix = "Internet", destination_address_prefix = "*", access = "Allow", priority = 300, direction = "Inbound" }
      } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [var.subnets]
}

run "rejects_default_route_bypass" {
  command = plan
  variables {
    subnets = {
      app               = { address_prefixes = ["10.200.0.0/24"], routes = { bypass = { address_prefix = "0.0.0.0/0", next_hop_type = "Internet" } } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [terraform_data.contracts]
}

run "rejects_wrong_provider_subscription" {
  command = plan
  variables { subscription_id = "99999999-9999-9999-9999-999999999999" }
  expect_failures = [terraform_data.contracts]
}

run "rejects_contract_drift" {
  command = plan
  variables {
    platform = {
      management_contract_version   = "2.0.0"
      connectivity_contract_version = "0.1.0"
      log_analytics_workspace_id    = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
      hub_virtual_network_id        = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
      hub_address_space             = ["10.102.0.0/21"]
      key_vault_private_dns_zone_id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      dns_server_ips                = ["10.102.0.10", "10.102.0.11"]
    }
  }
  expect_failures = [terraform_data.contracts]
}

run "approved_application_rules_are_preserved" {
  command = plan
  variables {
    subnets = {
      app = { address_prefixes = ["10.200.0.0/24"], rules = {
        approved-https = { protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.102.0.0/21", destination_address_prefix = "*", access = "Allow", priority = 300, direction = "Inbound" }
      } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  assert {
    condition     = local.nsg_rules.app.approved-https.priority == 300 && local.nsg_rules.app.baseline-deny-inbound.priority == 4096
    error_message = "Approved application access must coexist with, not replace, the default-deny baseline."
  }
}

run "rejects_baseline_rule_name_override" {
  command = plan
  variables {
    subnets = {
      app = { address_prefixes = ["10.200.0.0/24"], rules = {
        baseline-deny-inbound = { protocol = "Tcp", destination_port_range = "443", source_address_prefix = "10.102.0.0/21", destination_address_prefix = "*", access = "Allow", priority = 300, direction = "Inbound" }
      } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [terraform_data.contracts]
}

run "rejects_delegated_private_endpoint_subnet" {
  command = plan
  variables {
    subnets = {
      app               = { address_prefixes = ["10.200.0.0/24"] }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"], delegations = { application = { name = "Microsoft.Web/serverFarms" } } }
    }
  }
  expect_failures = [var.subnets]
}

run "rejects_azure_undersized_subnet" {
  command = plan
  variables { subnets = { app = { address_prefixes = ["10.200.0.0/24"] }, private_endpoints = { address_prefixes = ["10.200.1.0/30"] } } }
  expect_failures = [var.subnets]
}

run "rejects_subnet_that_contains_the_vnet" {
  command = plan
  variables { subnets = { app = { address_prefixes = ["10.200.0.0/16"] }, private_endpoints = { address_prefixes = ["10.200.1.0/27"] } } }
  expect_failures = [terraform_data.contracts]
}

run "production_operations_are_not_only_a_name_change" {
  command = apply
  assert {
    condition = (
      output.environment_profile.tier == "production" &&
      module.application_insights[0].security_configuration.sampling_percentage == 100 &&
      output.environment_profile.alert_severity == 1 && output.environment_profile.alert_frequency == "PT1M" &&
      module.telemetry_access.assignments.workload.scope == module.application_insights[0].id &&
      module.telemetry_access.assignments.workload.role_definition_name == "Monitoring Metrics Publisher" &&
      length(output.application_services.action_group_ids) > 0 && length(output.application_services.storage) == 0
    )
    error_message = "Production requires stronger operational defaults, scoped telemetry publishing, real alert routing and no unused storage."
  }
}

run "nonproduction_uses_lower_cost_operational_defaults" {
  command = plan
  variables { environment = "dev" }
  assert {
    condition = (module.application_insights[0].security_configuration.sampling_percentage == 20 && output.environment_profile.alert_frequency == "PT5M" &&
    output.environment_profile.alert_severity == 3 && module.key_vault[0].security_configuration.purge_protection_enabled)
    error_message = "Non-production reduces telemetry volume/alert urgency without weakening vault security."
  }
}

run "production_blob_storage_is_private_resilient_and_monitored" {
  command = apply
  variables {
    storage_accounts = { data = { grant_workload_blob_access = true } }
    platform = {
      management_contract_version      = "0.1.0", connectivity_contract_version = "0.1.0"
      log_analytics_workspace_id       = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
      hub_virtual_network_id           = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
      hub_address_space                = ["10.102.0.0/21"], dns_server_ips = ["10.102.0.10", "10.102.0.11"]
      key_vault_private_dns_zone_id    = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      storage_blob_private_dns_zone_id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
    }
  }
  assert {
    condition = (
      local.storage_settings.data.account_replication_type == "ZRS" &&
      module.storage.data.name == local.storage_settings.data.name &&
      module.storage.data.resource_group_name == module.resource_groups.group_names["data"] && module.storage.data.location == var.location &&
      local.storage_settings.data.blob_properties.delete_retention_days == 30 && local.storage_settings.data.blob_properties.versioning_enabled &&
      !local.storage_settings.data.public_network_access_enabled && !local.storage_settings.data.shared_access_key_enabled &&
      local.storage_settings.data.min_tls_version == "TLS1_2" && local.storage_settings.data.https_traffic_only_enabled &&
      local.storage_settings.data.infrastructure_encryption_enabled && !local.storage_settings.data.allow_nested_items_to_be_public &&
      local.storage_settings.data.default_to_oauth_authentication && !local.storage_settings.data.cross_tenant_replication_enabled &&
      local.storage_settings.data.network_rules.default_action == "Deny" && local.storage_settings.data.network_rules.bypass == ["None"] &&
      local.storage_settings.data.blob_properties.change_feed_enabled && local.storage_settings.data.blob_properties.container_delete_retention_days == 30 &&
      module.storage_access.assignments.data.scope == module.storage.data.id &&
      module.storage_blob_diagnostics.data.target_resource_id == "${module.storage.data.id}/blobServices/default" &&
      module.storage_blob_diagnostics.data.destinations.log_analytics_workspace_id == var.platform.log_analytics_workspace_id &&
      contains(keys(output.attachment_contract.private_dns_zones), "storage_blob") && length(module.storage_endpoints) == 1
    )
    error_message = "Production storage module inputs must require resilience, private/keyless access and recovery; composition must scope data access and Blob diagnostics correctly."
  }
}

run "rejects_storage_without_approved_central_dns" {
  command = plan
  variables {
    storage_accounts = { data = {} }
    platform = {
      management_contract_version   = "0.1.0", connectivity_contract_version = "0.1.0"
      log_analytics_workspace_id    = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
      hub_virtual_network_id        = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
      hub_address_space             = ["10.102.0.0/21"], dns_server_ips = ["10.102.0.10"]
      key_vault_private_dns_zone_id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
    }
  }
  expect_failures = [terraform_data.capability_contract]
}

run "rejects_unroutable_operational_alerts" {
  command = plan
  variables { operations = {} }
  expect_failures = [terraform_data.capability_contract]
}

run "rejects_private_monitoring_without_ready_platform_path" {
  command = plan
  variables { monitoring = { enabled = true, create_application_insights = true, internet_ingestion_enabled = false } }
  expect_failures = [var.monitoring]
}

run "phase_one_default_has_no_deferred_or_duplicate_services" {
  command = apply
  variables {
    monitoring = {}
    operations = {}
  }
  assert {
    condition = (
      toset(keys(output.resource_group_names)) == toset(["network", "security", "application"]) &&
      output.resource_group_names.application == "orders-cus-prod-app-rg" &&
      length(module.application_insights) == 0 && length(module.failed_requests_alert) == 0 &&
      length(module.alert_contacts) == 0 && length(module.telemetry_access.ids) == 0 &&
      output.application_services.application_insights_id == null && !contains(keys(output.application_services), "budget_id") &&
      output.application_services.failed_requests_alert_id == null && length(module.storage) == 0 &&
      length(azurerm_backup_protected_vm.workload) == 0 && module.key_vault[0].private_endpoint_id != null
    )
    error_message = "Phase 1 must deploy the three placement RGs and private vault, not Phase 2 telemetry/alerts, a duplicate onboarding budget, unused storage or compute backups."
  }
}

run "hub_and_approved_remote_routes_require_inspection" {
  command = apply
  variables { inspection_address_prefixes = ["10.102.8.0/26", "172.20.0.0/16", "10.201.0.0/20"] }
  assert {
    condition = (
      alltrue([for subnet in values(var.subnets) : !subnet.bgp_route_propagation_enabled]) &&
      alltrue([for table in values(local.routes) : alltrue([for prefix in concat(var.platform.hub_address_space, ["10.169.0.0/16"], var.inspection_address_prefixes) :
        anytrue([for route in values(table) : route.address_prefix == prefix && route.next_hop_type == "VirtualAppliance" && route.next_hop_in_ip_address == var.egress_next_hop_ip])
      ])]) &&
      alltrue([for rules in values(local.nsg_rules) : rules.baseline-deny-sunstream-inbound.priority == 100 && rules.baseline-deny-sunstream-outbound.priority == 100])
    )
    error_message = "Hub, identity, on-prem and other approved spoke routes must use the NVA; partner traffic stays denied and learned routes cannot bypass inspection."
  }
}

run "rejects_inspection_of_own_spoke" {
  command = plan
  variables { inspection_address_prefixes = ["10.200.0.0/16"] }
  expect_failures = [terraform_data.contracts]
}

run "rejects_gateway_route_propagation_bypass" {
  command = plan
  variables {
    subnets = {
      app               = { address_prefixes = ["10.200.0.0/24"], bgp_route_propagation_enabled = true }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [terraform_data.contracts]
}

run "rejects_direct_gateway_custom_route" {
  command = plan
  variables {
    subnets = {
      app               = { address_prefixes = ["10.200.0.0/24"], routes = { bypass = { address_prefix = "172.20.0.0/16", next_hop_type = "VirtualNetworkGateway" } } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [terraform_data.contracts]
}

run "rejects_duplicate_inspection_prefix_in_custom_routes" {
  command = plan
  variables {
    subnets = {
      app               = { address_prefixes = ["10.200.0.0/24"], routes = { duplicate = { address_prefix = "10.102.0.0/21", next_hop_type = "None" } } }
      private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
    }
  }
  expect_failures = [terraform_data.contracts]
}

run "rejects_alerts_without_enabled_telemetry" {
  command = plan
  variables { monitoring = { alerts_enabled = true } }
  expect_failures = [var.monitoring]
}

run "rejects_missing_governance_mandatory_tag" {
  command = plan
  variables {
    platform = {
      management_contract_version   = "0.1.0", connectivity_contract_version = "0.1.0"
      log_analytics_workspace_id    = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
      hub_virtual_network_id        = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
      hub_address_space             = ["10.102.0.0/21"], dns_server_ips = ["10.102.0.10"]
      key_vault_private_dns_zone_id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
      mandatory_tag_keys            = ["unprovided_governance_metadata"]
    }
  }
  expect_failures = [terraform_data.contracts]
}

run "nonproduction_storage_is_lower_cost_but_still_private" {
  command = apply
  variables {
    environment      = "dev"
    storage_accounts = { data = {} }
  }
  assert {
    condition = (local.storage_settings.data.account_replication_type == "LRS" && local.storage_settings.data.blob_properties.delete_retention_days == 7 &&
      module.storage.data.resource_group_name == module.resource_groups.group_names["data"] && module.storage.data.location == var.location &&
      local.storage_settings.data.blob_properties.container_delete_retention_days == 7 && local.storage_settings.data.blob_properties.versioning_enabled &&
      !local.storage_settings.data.public_network_access_enabled && !local.storage_settings.data.shared_access_key_enabled &&
    length(module.storage_access.ids) == 0)
    error_message = "Non-production storage module inputs must retain private/keyless access with LRS/7-day recovery and no implicit data access."
  }
}

run "rejects_non_resilient_production_storage" {
  command = plan
  variables { storage_accounts = { data = { replication_type = "LRS" } } }
  expect_failures = [terraform_data.capability_contract]
}

run "rejects_short_production_recovery_retention" {
  command = plan
  variables { storage_accounts = { data = { delete_retention_days = 7 } } }
  expect_failures = [terraform_data.capability_contract]
}

run "external_attachment_mode_does_not_own_storage_zone_link" {
  command = plan
  variables {
    storage_accounts      = { data = {} }
    manage_hub_attachment = false
  }
  assert {
    condition     = output.attachment_contract.owner == "central-attachment-workspace" && output.attachment_contract.storage_blob_private_dns_zone_id != null && output.attachment_contract.private_dns_zones.storage_blob.name == "privatelink.blob.core.windows.net"
    error_message = "The central owner receives the Blob zone attachment contract without a competing DNS link."
  }
}

run "rejects_old_spoke_owned_attachment_mode" {
  command = plan
  variables { manage_hub_attachment = true }
  expect_failures = [var.manage_hub_attachment]
}

run "backup_registers_existing_vms_without_creating_compute_or_vaults" {
  command = apply
  variables {
    backup = {
      recovery_vault_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/recovery/providers/Microsoft.RecoveryServices/vaults/approved-rsv"
      backup_policy_id  = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/recovery/providers/Microsoft.RecoveryServices/vaults/approved-rsv/backupPolicies/approved-production"
      virtual_machines  = { app = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/app/providers/Microsoft.Compute/virtualMachines/existing-app" }
    }
  }
  assert {
    condition = (azurerm_backup_protected_vm.workload["app"].source_vm_id == var.backup.virtual_machines.app &&
      azurerm_backup_protected_vm.workload["app"].backup_policy_id == var.backup.backup_policy_id &&
    azurerm_backup_protected_vm.workload["app"].recovery_vault_name == "approved-rsv")
    error_message = "Backup integration must enroll the supplied VM in the approved existing vault/policy."
  }
}

run "rejects_backup_policy_from_another_vault" {
  command = plan
  variables {
    backup = {
      recovery_vault_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/recovery/providers/Microsoft.RecoveryServices/vaults/approved-rsv"
      backup_policy_id  = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/recovery/providers/Microsoft.RecoveryServices/vaults/other-rsv/backupPolicies/wrong"
      virtual_machines  = { app = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/app/providers/Microsoft.Compute/virtualMachines/existing-app" }
    }
  }
  expect_failures = [var.backup]
}

run "NET_29_private_endpoints_are_owned_by_the_parent_vault_pattern" {
  command = apply
  assert {
    condition = (
      module.key_vault[0].private_endpoint_configuration.subnet_id == output.subnet_ids.private_endpoints &&
      module.key_vault[0].private_endpoint_configuration.target_resource_id == output.key_vault.id &&
      toset(module.key_vault[0].private_endpoint_configuration.subresource_names) == toset(["vault"]) &&
      toset(module.key_vault[0].private_endpoint_configuration.private_dns_zone_ids) == toset([var.platform.key_vault_private_dns_zone_id])
    )
    error_message = "NET-29 requires the parent resource's endpoint to target the correct resource, approved subnet, service group and central DNS zone."
  }
}

run "IAM_06_managed_identity_is_published_with_scoped_parent_roles" {
  command = apply
  assert {
    condition = (
      output.workload_identity.id == module.workload_identity.id && output.workload_identity.client_id == module.workload_identity.client_id &&
      output.workload_identity.principal_id == module.workload_identity.principal_id &&
      module.key_vault[0].role_assignments.reader-workload.principal_id == output.workload_identity.principal_id &&
      module.key_vault[0].role_assignments.reader-workload.scope == output.key_vault.id &&
      module.key_vault[0].role_assignments.reader-workload.role_definition_name == "Key Vault Secrets User" &&
      module.telemetry_access.assignments.workload.principal_id == output.workload_identity.principal_id &&
      module.telemetry_access.assignments.workload.scope == module.application_insights[0].id &&
      module.telemetry_access.assignments.workload.role_definition_name == "Monitoring Metrics Publisher" && length(module.storage_access.ids) == 0
    )
    error_message = "IAM-06 must publish the workload UAMI, scope its service roles to owned resources and avoid implicit Owner/Contributor or unused storage access."
  }
}
