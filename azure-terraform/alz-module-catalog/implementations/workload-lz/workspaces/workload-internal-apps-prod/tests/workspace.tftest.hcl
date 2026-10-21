mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = { subscription_id = "11111111-1111-1111-1111-111111111111", tenant_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/spoke" }
  }
  mock_resource "azurerm_subnet" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/spoke/subnets/private-endpoints" }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/networkSecurityGroups/app" }
  }
  mock_resource "azurerm_route_table" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/routeTables/app" }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = { principal_id = "55555555-5555-5555-5555-555555555555" }
  }
  mock_resource "azurerm_key_vault" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.KeyVault/vaults/fixture" }
  }
  mock_resource "azurerm_application_insights" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/operations/providers/Microsoft.Insights/components/orders-appi" }
  }
  mock_resource "azurerm_monitor_action_group" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/operations/providers/Microsoft.Insights/actionGroups/workload" }
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
mock_provider "time" {
  mock_resource "time_static" { defaults = { rfc3339 = "2026-10-13T12:00:00Z" } }
}
mock_provider "tfe" {
  mock_data "tfe_outputs" {
    defaults = {
      nonsensitive_values = {
        contract_version     = "0.1.0"
        mandatory_tag_keys   = ["application", "environment", "owner", "cost_center"]
        action_group_enabled = true
        action_group_ids = {
          primary  = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/actionGroups/platform-primary"
          security = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/actionGroups/security-only"
        }
        log_analytics_workspace_id        = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/law"
        hub_virtual_network_id            = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
        hub_virtual_network_address_space = ["10.102.0.0/21"]
        key_vault_private_dns_zone_id     = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
        dns_server_ips                    = ["10.102.0.10", "10.102.0.11"]
      }
      values = { contract_version = "DO_NOT_READ_SENSITIVE_OUTPUTS" }
    }
  }
}

run "committed_placeholders_are_inert" {
  command = plan
  assert {
    condition     = output.spoke == null && output.spoke_virtual_network_id == null && length(output.subnet_ids) == 0
    error_message = "Committed placeholders must not create a partial spoke or read client platform outputs."
  }
}

run "approved_shared_monitoring_is_referenced_without_duplicates" {
  command = apply
  variables {
    subscription_id              = "11111111-1111-1111-1111-111111111111"
    tenant_id                    = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    connectivity_subscription_id = "22222222-2222-2222-2222-222222222222"
    private_dns_subscription_id  = "33333333-3333-3333-3333-333333333333"
    tfe_organization             = "integration-fixture"
    spoke = {
      enabled            = true
      appcode            = "orders"
      address_space      = ["10.200.0.0/20"]
      egress_next_hop_ip = "10.102.0.4"
      subnets = {
        app               = { address_prefixes = ["10.200.0.0/24"] }
        private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
      }
      workload_tags = {
        application         = "orders", owner = "Applications", source_repo = "ado://Compeer/workloads", criticality_tier = "tier-2",
        data_classification = "confidential", lifecycle_state = "active", cost_center = "CC-0000", gl_category = "cloud-infrastructure", dr_tier = "silver"
      }
      monitoring = {
        enabled = true, alerts_enabled = true
        existing_application_insights = {
          id           = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/components/approved-application"
          workspace_id = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/law"
        }
      }
    }
  }
  assert {
    condition = (
      output.spoke.application_services.application_insights_owner == "existing-resource-owner" &&
      !output.spoke.application_services.application_insights_configuration_managed &&
      !output.spoke.application_services.telemetry_access_managed &&
      one(output.spoke.application_services.action_group_ids) == "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/actionGroups/platform-primary" &&
      length(output.spoke.application_services.created_action_group_ids) == 0 &&
      !contains(keys(output.spoke.application_services), "budget_id")
    )
    error_message = "The adapter must select only the approved primary audience from management outputs and reference existing telemetry without creating or taking ownership of shared services."
  }
}
run "enabled_workspace_consumes_public_contracts" {
  command = apply
  variables {
    subscription_id              = "11111111-1111-1111-1111-111111111111"
    tenant_id                    = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    connectivity_subscription_id = "22222222-2222-2222-2222-222222222222"
    private_dns_subscription_id  = "33333333-3333-3333-3333-333333333333"
    tfe_organization             = "integration-fixture"
    spoke = {
      enabled            = true
      appcode            = "orders"
      address_space      = ["10.200.0.0/20"]
      egress_next_hop_ip = "10.102.0.4"
      subnets = {
        app               = { address_prefixes = ["10.200.0.0/24"] }
        private_endpoints = { address_prefixes = ["10.200.1.0/27"] }
      }
      workload_tags = {
        application         = "orders", owner = "Applications", source_repo = "ado://Compeer/workloads", criticality_tier = "tier-2",
        data_classification = "confidential", lifecycle_state = "active", cost_center = "CC-0000", gl_category = "cloud-infrastructure", dr_tier = "silver"
      }
    }
  }
  assert {
    condition = (
      output.spoke.contract_version == "1.0.0" &&
      output.attachment_contract.owner == "central-attachment-workspace" &&
      output.attachment_contract.contract_version == "2.0.0" &&
      !contains(keys(output.attachment_contract), "peering_names") &&
      contains(keys(output.attachment_contract.private_dns_zones), "key_vault") &&
      toset(output.spoke.mandatory_tag_keys) == toset(["application", "environment", "owner", "cost_center"]) &&
      output.spoke.log_analytics_workspace_id == output.spoke.diagnostic_ownership.workspace_id &&
      toset(keys(output.spoke.resource_group_ids)) == toset(["network", "security", "application"]) &&
      output.spoke.attachment_contract.spoke_virtual_network_name == "orders-cus-prod-spoke-vnet" &&
      output.spoke.diagnostic_ownership.workspace_id == "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/law" &&
      output.spoke.security_baseline.flow_log_owner == "platform-policy" &&
      output.spoke.environment_profile.tier == "production" && output.spoke.environment_profile.alert_severity == 1 &&
      output.spoke.application_services.application_resource_group_name == "orders-cus-prod-app-rg" &&
      !contains(keys(output.spoke.application_services), "budget_id") && output.spoke.application_services.application_insights_id == null &&
      toset(keys(output.spoke.resource_group_names)) == toset(["network", "security", "application"])
    )
    error_message = "The environment workspace must deploy the shared blueprint from non-sensitive platform contracts, preserving service ownership."
  }
}
