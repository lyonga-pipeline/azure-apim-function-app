mock_provider "azurerm" {
  mock_resource "azurerm_private_endpoint" {
    defaults = {
      private_dns_zone_configs = [{
        name                = "vault"
        id                  = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.Network/privateEndpoints/vault/privateDnsZoneGroups/default/privateDnsZoneConfigs/vault"
        private_dns_zone_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
        record_sets         = []
      }]
    }
  }
  mock_resource "azurerm_key_vault" {
    defaults = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault" }
  }
}

run "rejects_turning_off_required_audit_coverage" {
  command = plan
  variables { diagnostics = { enabled = false } }
  expect_failures = [var.diagnostics]
}

run "rejects_external_audit_setting_on_another_vault" {
  command = plan
  override_module {
    target  = module.vault
    outputs = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault" }
  }
  variables {
    diagnostics = {
      enabled = false
      existing_setting = {
        id                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.KeyVault/vaults/other-vault/providers/Microsoft.Insights/diagnosticSettings/external"
        workspace_id      = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
        log_categories    = ["AuditEvent"]
        metric_categories = ["AllMetrics"]
      }
    }
  }
  expect_failures = [terraform_data.diagnostic_reuse_contract]
}

variables {
  resource_group_name        = "internal-apps-orders-cus-prod-security-rg"
  location                   = "centralus"
  tenant_id                  = "11111111-1111-1111-1111-111111111111"
  environment                = "prod"
  appcode                    = "orders"
  private_endpoint_subnet_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/spoke/subnets/private-endpoints"
  private_dns_zone_id        = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  log_analytics_workspace_id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
  tags = {
    environment = "prod", application = "orders", appcode = "orders", owner = "Applications", source_repo = "ado://Compeer/workloads",
    created_on  = "2026-10-13", criticality_tier = "tier-2", data_classification = "confidential", lifecycle_state = "active",
    cost_center = "CC-0000", gl_category = "cloud-infrastructure", created_by = "Terraform"
  }
}

run "secure_baseline_and_private_dns_are_wired" {
  command = plan
  assert {
    condition = (
      module.vault.name == "orders-cus-prod-vault" &&
      module.vault.security_configuration.rbac_authorization_enabled &&
      !module.vault.security_configuration.public_network_access_enabled &&
      module.vault.security_configuration.purge_protection_enabled &&
      module.vault.security_configuration.soft_delete_retention_days == 90 &&
      module.vault.security_configuration.network_acl_default_action == "Deny" &&
      module.vault.security_configuration.network_acl_bypass == "None" &&
      !module.vault.security_configuration.enabled_for_deployment &&
      !module.vault.security_configuration.enabled_for_disk_encryption &&
      !module.vault.security_configuration.enabled_for_template_deployment
    )
    error_message = "The vault must use the naming module and a private, RBAC-only, purge-protected baseline without broad service bypasses."
  }
  assert {
    condition = (
      module.private_endpoint.subnet_id == var.private_endpoint_subnet_id &&
      module.private_endpoint.private_service_connection[0].subresource_names == tolist(["vault"]) &&
      module.diagnostics[0].destinations.log_analytics_workspace_id == var.log_analytics_workspace_id &&
      length(local.role_assignments) == 0
    )
    error_message = "Vault access must use the approved private subnet/central LAW and must not grant deployment-identity secret access implicitly."
  }
}

run "public_endpoint_and_security_outputs_use_child_contracts" {
  command = apply
  assert {
    condition = (
      output.security_configuration == module.vault.security_configuration &&
      output.security_configuration.rbac_authorization_enabled &&
      !output.security_configuration.public_network_access_enabled &&
      output.security_configuration.purge_protection_enabled &&
      output.security_configuration.soft_delete_retention_days == 90
    )
    error_message = "The public security output must preserve observed child attributes, not desired constants or a null fallback."
  }
  assert {
    condition = (
      output.private_endpoint_configuration.subnet_id == var.private_endpoint_subnet_id &&
      output.private_endpoint_configuration.target_resource_id == module.vault.id &&
      toset(output.private_endpoint_configuration.subresource_names) == toset(["vault"]) &&
      output.private_endpoint_configuration.private_dns_zone_ids == [var.private_dns_zone_id]
    )
    error_message = "The endpoint output must read private_dns_zone_configs from the supported base-module interface."
  }
}

run "scoped_identity_and_operator_roles" {
  command = plan
  variables {
    secret_readers           = { application = { principal_id = "44444444-4444-4444-4444-444444444444" } }
    secret_officer_group_ids = { security = "55555555-5555-5555-5555-555555555555" }
  }
  assert {
    condition = (
      local.role_assignments.reader-application.role_definition_name == "Key Vault Secrets User" &&
      local.role_assignments.reader-application.principal_type == "ServicePrincipal" &&
      local.role_assignments.officer-security.role_definition_name == "Key Vault Secrets Officer" &&
      local.role_assignments.officer-security.principal_type == "Group"
    )
    error_message = "Workload identities may read secrets; explicit operator groups may manage secrets, not vault RBAC/Owner permissions."
  }
}

run "nonproduction_has_identical_security_controls" {
  command = plan
  variables {
    environment = "dev"
    tags = {
      environment = "dev", application = "orders", appcode = "orders", owner = "Applications", source_repo = "ado://Compeer/workloads",
      created_on  = "2026-10-13", criticality_tier = "tier-2", data_classification = "confidential", lifecycle_state = "active",
      cost_center = "CC-0000", gl_category = "cloud-infrastructure", created_by = "Terraform"
    }
  }
  assert {
    condition     = module.vault.name == "orders-cus-dev-vault" && module.vault.security_configuration.purge_protection_enabled && !module.vault.security_configuration.public_network_access_enabled
    error_message = "Non-production must use environment-specific names without weakening the vault baseline."
  }
}

run "rejects_mislabeled_environment" {
  command = plan
  variables { environment = "dev" }
  expect_failures = [terraform_data.tag_contract]
}

run "rejects_reused_vault_diagnostics_to_another_workspace" {
  command = plan
  variables {
    diagnostics = {
      existing_setting = {
        id                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault/providers/Microsoft.Insights/diagnosticSettings/external"
        workspace_id      = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/wrong-law"
        log_categories    = ["AuditEvent"]
        metric_categories = ["AllMetrics"]
      }
    }
  }
  expect_failures = [terraform_data.tag_contract]
}

run "rejects_wrong_private_dns_zone" {
  command = plan
  variables { private_dns_zone_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net" }
  expect_failures = [var.private_dns_zone_id]
}

run "rejects_workspace_guid_instead_of_resource_id" {
  command = plan
  variables { log_analytics_workspace_id = "33333333-3333-3333-3333-333333333333" }
  expect_failures = [var.log_analytics_workspace_id]
}

run "rejects_placeholder_principal" {
  command = plan
  variables { secret_readers = { application = { principal_id = "00000000-0000-0000-0000-000000000000" } } }
  expect_failures = [var.secret_readers]
}

run "rejects_missing_mandatory_tags" {
  command = plan
  variables { tags = { environment = "prod" } }
  expect_failures = [var.tags]
}
