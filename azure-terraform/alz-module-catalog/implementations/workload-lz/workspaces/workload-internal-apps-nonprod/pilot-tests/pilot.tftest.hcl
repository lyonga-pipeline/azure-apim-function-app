# Exercise the actual pilot tfvars with synthetic identity/DNS/NVA test context.
mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      subscription_id = "11111111-1111-1111-1111-111111111111"
      tenant_id       = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/pilot" }
  }
  mock_resource "azurerm_subnet" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/pilot/subnets/private-endpoints" }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/networkSecurityGroups/pilot" }
  }
  mock_resource "azurerm_route_table" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/routeTables/pilot" }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = { principal_id = "55555555-5555-5555-5555-555555555555" }
  }
  mock_resource "azurerm_key_vault" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.KeyVault/vaults/pilot" }
  }
  mock_resource "azurerm_storage_account" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/data/providers/Microsoft.Storage/storageAccounts/pilotdata" }
  }
  mock_resource "azurerm_application_insights" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/operations/providers/Microsoft.Insights/components/pilot" }
  }
}
mock_provider "time" {
  mock_resource "time_static" { defaults = { rfc3339 = "2026-11-02T12:00:00Z" } }
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
        log_analytics_workspace_id        = "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/law"
        hub_virtual_network_id            = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/hub/providers/Microsoft.Network/virtualNetworks/hub"
        hub_virtual_network_address_space = ["10.102.0.0/21"]
        key_vault_private_dns_zone_id     = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
        storage_blob_private_dns_zone_id  = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
        dns_server_ips                    = ["10.102.0.10", "10.102.0.11"]
      }
    }
  }
}

run "pilot_is_disabled_and_uses_two_complete_subnets" {
  command = plan
  assert {
    condition = (
      !var.spoke.enabled && output.spoke == null && var.environment == "dev" &&
      toset(keys(var.spoke.subnets)) == toset(["application", "private_endpoints"]) &&
      one(var.spoke.address_space) == "10.102.64.0/27" &&
      one(var.spoke.subnets.application.address_prefixes) == "10.102.64.0/28" &&
      one(var.spoke.subnets.private_endpoints.address_prefixes) == "10.102.64.16/28" &&
      var.spoke.egress_next_hop_ip == "REPLACE_APPROVED_HUB_NVA_IPV4" &&
      var.spoke.subnets.application.rules.internal-https.destination_address_prefix == "10.102.64.0/28" &&
      length(data.tfe_outputs.management) + length(data.tfe_outputs.connectivity) + length(data.tfe_outputs.governance) == 0
    )
    error_message = "The pilot must remain inert until approved, with only non-overlapping application/private-endpoint subnets and the correct HTTPS destination."
  }
}

run "enabled_pilot_preserves_services_and_central_attachment_ownership" {
  command = apply
  variables {
    subscription_id = "11111111-1111-1111-1111-111111111111"
    tenant_id       = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    spoke           = merge(var.spoke, { enabled = true, egress_next_hop_ip = "10.102.4.42" })
  }
  assert {
    condition = (
      toset(keys(output.subnet_ids)) == toset(["application", "private_endpoints"]) &&
      toset(keys(output.spoke.security_baseline.nsg_ids)) == toset(["application", "private_endpoints"]) &&
      toset(keys(output.spoke.security_baseline.route_table_ids)) == toset(["application", "private_endpoints"]) &&
      output.spoke.security_baseline.egress_next_hop_ip == "10.102.4.42" &&
      !output.spoke.security_baseline.default_outbound_access_enabled &&
      !output.spoke.security_baseline.gateway_bgp_propagation_enabled &&
      output.attachment_contract.owner == "central-attachment-workspace" &&
      output.attachment_contract.spoke_virtual_network_name == "pltinapp-cus-dev-spoke-vnet" &&
      !output.spoke.security_baseline.key_vault_public_access &&
      output.spoke.security_baseline.key_vault_rbac && output.spoke.security_baseline.key_vault_purge_protection
    )
    error_message = "Both pilot subnets need baseline NSGs/UDRs, the configured trust frontend and private RBAC vault; central attachment retains both peerings."
  }
  assert {
    condition = (
      toset(keys(output.spoke.application_services.storage)) == toset(["data"]) &&
      output.spoke.application_services.storage.data.replication_type == "ZRS" &&
      output.spoke.application_services.storage.data.delete_retention_days == 30 &&
      output.spoke.application_services.application_insights_configuration_managed &&
      output.spoke.application_services.failed_requests_alert_owner == "this-workload-state" &&
      one(output.spoke.application_services.action_group_ids) == "/subscriptions/44444444-4444-4444-4444-444444444444/resourceGroups/monitoring/providers/Microsoft.Insights/actionGroups/platform-primary" &&
      length(output.spoke.application_services.created_action_group_ids) == 0 &&
      toset(keys(output.spoke.diagnostic_ownership.targets)) == toset(["key_vault", "storage.data.account", "storage.data.blob"])
    )
    error_message = "The supplied vault/Blob/telemetry choices must retain audit coverage and reuse the approved primary action group without creating another group."
  }
}

run "pilot_cannot_be_relabelled_as_production" {
  command = plan
  variables { environment = "prod" }
  expect_failures = [var.environment]
}
