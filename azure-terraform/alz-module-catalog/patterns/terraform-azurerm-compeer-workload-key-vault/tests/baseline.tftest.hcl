mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = { tenant_id = "11111111-1111-1111-1111-111111111111", subscription_id = "11111111-1111-1111-1111-111111111111" }
  }
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
      module.private_endpoint["default"].subnet_id == var.private_endpoint_subnet_id &&
      module.private_endpoint["default"].private_service_connection[0].subresource_names == tolist(["vault"]) &&
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

run "multiple_endpoints_keys_and_existing_alert_routes" {
  command = apply
  variables {
    sku_name = "premium"
    private_endpoints = {
      default = {
        subnet_id           = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/spoke/subnets/private-endpoints"
        private_dns_zone_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
        private_ip_address  = "10.200.1.6"
      }
      recovery = {
        subnet_id           = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/recovery/subnets/private-endpoints"
        private_dns_zone_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
        location            = "eastus2"
        manual_connection   = true
        request_message     = "APPROVED-CHANGE: recovery access"
      }
    }
    keys        = { application-cmk = { key_type = "RSA-HSM", key_size = 3072, key_opts = ["wrapKey", "unwrapKey"], expiration_date = "2027-10-22T00:00:00Z", rotation_policy = { expire_after = "P180D", notify_before_expiry = "P30D", automatic = { time_after_creation = "P90D" } } } }
    data_access = { cmk = { principal_id = "44444444-4444-4444-4444-444444444444", role_definition_name = "Key Vault Crypto Service Encryption User" } }
    monitoring  = { enabled = true, action_group_ids = ["/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/monitoring/providers/Microsoft.Insights/actionGroups/oncall"] }
  }
  assert {
    condition = (
      toset(keys(output.private_endpoints)) == toset(["default", "recovery"]) &&
      toset(keys(output.key_ids)) == toset(["application-cmk"]) &&
      toset(keys(output.key_versionless_ids)) == toset(["application-cmk"]) &&
      toset(keys(output.metric_alert_ids)) == toset(["availability", "latency", "saturation"]) &&
      output.security_configuration.sku_name == "premium" &&
      !output.security_configuration.public_network_access_enabled &&
      local.role_assignments.data-cmk.role_definition_name == "Key Vault Crypto Service Encryption User" &&
      local.keys.application-cmk.rotation_policy.automatic.time_after_creation == "P90D"
    )
    error_message = "Advanced options must remain private/RBAC and compose keyed endpoints, rotating HSM keys and routed metric alerts."
  }
}
run "approved_public_firewall_exception_has_no_endpoint" {
  command = apply
  variables {
    private_endpoints = {}
    network_access    = { mode = "restricted_public", exception_reference = "APPROVED-SEC-123", ip_rules = ["203.0.113.10/32"] }
  }
  assert {
    condition = (
      output.security_configuration.public_network_access_enabled &&
      output.security_configuration.network_acl_default_action == "Deny" &&
      output.security_configuration.network_acl_bypass == "None" &&
      output.private_endpoint_id == null && output.private_endpoint_configuration == null &&
      length(output.private_endpoints) == 0 && output.security_configuration.rbac_authorization_enabled
    )
    error_message = "The explicit exception must retain deny-by-default/RBAC/audit and never invent an endpoint."
  }
}
run "explicit_trusted_service_bypass_is_scoped_exception" {
  command = plan
  variables { network_access = { trusted_services_bypass = true, exception_reference = "APPROVED-SEC-124" } }
  assert {
    condition     = !module.vault.security_configuration.public_network_access_enabled && module.vault.security_configuration.network_acl_bypass == "AzureServices"
    error_message = "Trusted service access is explicitly approved, not a public endpoint switch."
  }
}
run "reuse_compliant_audit_setting_without_second_owner" {
  command = apply
  override_module {
    target  = module.vault
    outputs = { id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault" }
  }
  variables {
    diagnostics = {
      enabled = false
      existing_setting = {
        id                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault/providers/Microsoft.Insights/diagnosticSettings/platform"
        workspace_id      = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
        log_categories    = ["AuditEvent"]
        metric_categories = ["AllMetrics"]
      }
    }
  }
  assert {
    condition     = length(module.diagnostics) == 0 && length(output.diagnostic_ownership.terraform_resource_ids) == 0 && output.diagnostic_setting_id == var.diagnostics.existing_setting.id
    error_message = "Reuse must not create a duplicate setting or claim external ownership."
  }
}
run "additional_audit_destinations_preserve_central_law" {
  command = plan
  variables {
    diagnostics = {
      log_analytics_destination_type = "Dedicated"
      storage_account_id             = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/archive/providers/Microsoft.Storage/storageAccounts/auditarchive"
      eventhub_authorization_rule_id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/siem/providers/Microsoft.EventHub/namespaces/siem/authorizationRules/send"
      eventhub_name                  = "audit"
    }
  }
  assert {
    condition     = module.diagnostics[0].destinations.log_analytics_workspace_id == var.log_analytics_workspace_id && module.diagnostics[0].destinations.log_analytics_destination_type == "Dedicated" && module.diagnostics[0].destinations.storage_account_id == var.diagnostics.storage_account_id && module.diagnostics[0].destinations.eventhub_name == "audit"
    error_message = "Extra audit sinks must supplement, not replace, required central audit logging."
  }
}

run "rejects_private_mode_without_an_endpoint" {
  command = plan
  variables {
    private_endpoints = {}
  }
  expect_failures = [terraform_data.tag_contract]
}

run "rejects_public_without_exception" {
  command = plan
  variables {
    private_endpoints = {}
    network_access    = { mode = "restricted_public", ip_rules = ["203.0.113.10/32"] }
  }
  expect_failures = [var.network_access]
}

run "rejects_public_without_explicit_allowlist" {
  command = plan
  variables {
    network_access = { mode = "restricted_public", exception_reference = "SEC-123" }
  }
  expect_failures = [var.network_access]
}

run "rejects_internet_wide_firewall" {
  command = plan
  variables {
    network_access = { mode = "restricted_public", exception_reference = "SEC-123", ip_rules = ["0.0.0.0/0"] }
  }
  expect_failures = [var.network_access]
}

run "rejects_private_addresses_as_public_firewall_rules" {
  command = plan
  variables {
    network_access = { mode = "restricted_public", exception_reference = "SEC-123", ip_rules = ["10.200.1.6/32"] }
  }
  expect_failures = [terraform_data.tag_contract]
}

run "rejects_trusted_service_bypass_without_approval" {
  command = plan
  variables {
    network_access = { trusted_services_bypass = true }
  }
  expect_failures = [var.network_access]
}

run "rejects_owner_role" {
  command = plan
  variables {
    data_access = { app = { principal_id = "44444444-4444-4444-4444-444444444444", role_definition_name = "Owner" } }
  }
  expect_failures = [var.data_access]
}

run "rejects_individual_user_grants" {
  command = plan
  variables {
    data_access = { app = { principal_id = "44444444-4444-4444-4444-444444444444", principal_type = "User", role_definition_name = "Key Vault Secrets User" } }
  }
  expect_failures = [var.data_access]
}

run "rejects_duplicate_principal_role" {
  command = plan
  variables {
    secret_readers = { app = { principal_id = "44444444-4444-4444-4444-444444444444" } }
    data_access    = { app = { principal_id = "44444444-4444-4444-4444-444444444444", role_definition_name = "Key Vault Secrets User" } }
  }
  expect_failures = [terraform_data.tag_contract]
}

run "rejects_wrong_provider_tenant" {
  command = plan
  variables {
    tenant_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  }
  expect_failures = [terraform_data.tag_contract]
}

run "rejects_hsm_key_in_standard_sku" {
  command = plan
  variables {
    keys = { cmk = { key_type = "RSA-HSM", key_size = 3072, key_opts = ["wrapKey", "unwrapKey"], expiration_date = "2027-10-22T00:00:00Z", rotation_policy = { expire_after = "P180D", notify_before_expiry = "P30D", automatic = { time_after_creation = "P90D" } } } }
  }
  expect_failures = [terraform_data.tag_contract]
}

run "rejects_alerts_without_routes" {
  command = plan
  variables {
    monitoring = { enabled = true }
  }
  expect_failures = [var.monitoring]
}

run "rejects_alert_frequency_longer_than_window" {
  command = plan
  variables {
    monitoring = { frequency = "PT15M", window_size = "PT5M" }
  }
  expect_failures = [terraform_data.tag_contract]
}

run "rejects_extra_destinations_for_externally_owned_setting" {
  command = plan
  variables {
    diagnostics = {
      existing_setting = {
        id                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/security/providers/Microsoft.KeyVault/vaults/orders-cus-prod-vault/providers/Microsoft.Insights/diagnosticSettings/platform"
        workspace_id      = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/monitoring/providers/Microsoft.OperationalInsights/workspaces/central-law"
        log_categories    = ["AuditEvent"]
        metric_categories = ["AllMetrics"]
      }
      storage_account_id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/archive/providers/Microsoft.Storage/storageAccounts/auditarchive"
    }
  }
  expect_failures = [var.diagnostics]
}

run "rejects_endpoint_in_another_subscription" {
  command = plan
  variables {
    private_endpoints = {
      default = {
        subnet_id           = "/subscriptions/99999999-9999-9999-9999-999999999999/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/spoke/subnets/private-endpoints"
        private_dns_zone_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
        private_ip_address  = "10.200.1.6"
      }
      recovery = {
        subnet_id           = "/subscriptions/99999999-9999-9999-9999-999999999999/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/recovery/subnets/private-endpoints"
        private_dns_zone_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
        location            = "eastus2"
        manual_connection   = true
        request_message     = "APPROVED-CHANGE: recovery access"
      }
    }
  }
  expect_failures = [terraform_data.tag_contract]
}

run "rejects_wrong_zone_in_endpoint_map" {
  command = plan
  variables {
    private_endpoints = {
      default = {
        subnet_id           = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/spoke/subnets/private-endpoints"
        private_dns_zone_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
        private_ip_address  = "10.200.1.6"
      }
      recovery = {
        subnet_id           = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/recovery/subnets/private-endpoints"
        private_dns_zone_id = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
        location            = "eastus2"
        manual_connection   = true
        request_message     = "APPROVED-CHANGE: recovery access"
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "rejects_weak_key_parameters" {
  command = plan
  override_module {
    target  = module.keys
    outputs = { ids = {}, versionless_ids = {} }
  }
  variables {
    sku_name = "premium"
    keys     = { cmk = { key_type = "RSA", key_size = 1024, key_opts = ["wrapKey", "unwrapKey"], expiration_date = "2027-10-22T00:00:00Z", rotation_policy = { expire_after = "P180D", notify_before_expiry = "P30D", automatic = { time_after_creation = "P90D" } } } }
  }
  expect_failures = [var.keys]
}

run "rejects_rotation_without_a_trigger" {
  command = plan
  override_module {
    target  = module.keys
    outputs = { ids = {}, versionless_ids = {} }
  }
  variables {
    sku_name = "premium"
    keys     = { cmk = { key_type = "RSA-HSM", key_size = 3072, key_opts = ["wrapKey", "unwrapKey"], expiration_date = "2027-10-22T00:00:00Z", rotation_policy = { expire_after = "P180D", notify_before_expiry = "P30D", automatic = {} } } }
  }
  expect_failures = [var.keys]
}

run "rejects_two_rotation_triggers" {
  command = plan
  override_module {
    target  = module.keys
    outputs = { ids = {}, versionless_ids = {} }
  }
  variables {
    sku_name = "premium"
    keys     = { cmk = { key_type = "RSA-HSM", key_size = 3072, key_opts = ["wrapKey", "unwrapKey"], expiration_date = "2027-10-22T00:00:00Z", rotation_policy = { expire_after = "P180D", notify_before_expiry = "P30D", automatic = { time_after_creation = "P90D", time_before_expiry = "P30D" } } } }
  }
  expect_failures = [var.keys]
}

run "rejects_rotation_after_expiration" {
  command = plan
  override_module {
    target  = module.keys
    outputs = { ids = {}, versionless_ids = {} }
  }
  variables {
    sku_name = "premium"
    keys     = { cmk = { key_type = "RSA-HSM", key_size = 3072, key_opts = ["wrapKey", "unwrapKey"], expiration_date = "2027-10-22T00:00:00Z", rotation_policy = { expire_after = "P180D", notify_before_expiry = "P30D", automatic = { time_after_creation = "P200D" } } } }
  }
  expect_failures = [var.keys]
}
