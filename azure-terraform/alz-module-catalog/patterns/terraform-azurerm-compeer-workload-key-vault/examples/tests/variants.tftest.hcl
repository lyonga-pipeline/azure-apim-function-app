mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = { tenant_id = "11111111-1111-1111-1111-111111111111", subscription_id = "11111111-1111-1111-1111-111111111111" }
  }
  mock_resource "azurerm_key_vault" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-prod-security-rg/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault" }
  }
  mock_resource "azurerm_private_endpoint" {
    defaults = {
      private_dns_zone_configs = [{
        name                = "vault"
        id                  = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/orders-cus-prod-security-rg/providers/Microsoft.Network/privateEndpoints/vault/privateDnsZoneGroups/default/privateDnsZoneConfigs/vault"
        private_dns_zone_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
        record_sets         = []
      }]
    }
  }
}

run "examples_are_inert_before_approval" {
  command = plan
  assert {
    condition     = output.vault == null && length(module.vault) == 0
    error_message = "Checked-in examples must never create resources or read Azure until enabled."
  }
}

run "enabling_requires_explicit_acknowledgement" {
  command = plan
  variables { enabled = true }
  expect_failures = [terraform_data.approval]
}

run "approved_variant_composes_real_modules_with_mock_azure" {
  command = apply
  variables {
    enabled             = true
    deployment_approved = true
  }
  assert {
    condition = (
      output.vault.security_configuration.rbac_authorization_enabled &&
      output.vault.security_configuration.purge_protection_enabled &&
      output.vault.security_configuration.soft_delete_retention_days == 90 &&
      output.vault.security_configuration.network_acl_default_action == "Deny" &&
      output.vault.security_configuration.public_network_access_enabled == (var.network_access.mode == "restricted_public") &&
      length(output.vault.private_endpoints) == length(var.private_endpoints) &&
      length(output.vault.key_ids) == length(var.keys) &&
      length(output.vault.metric_alert_ids) == (var.monitoring.enabled ? 3 : 0) &&
      output.vault.diagnostic_setting_id != null
    )
    error_message = "Every actual tfvars variant must retain RBAC, purge/recovery, explicit networking and required audit coverage."
  }
}
