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
  operations = {
    notification_emails = ["workload-ops@example.com"]
    budget              = { amount = 1000, start_date = "2026-10-01T00:00:00Z" }
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

run "production_spoke_composes_real_modules_with_mocked_azure" {
  command = apply
  assert {
    condition = (
      output.contract_version == "1.0.0" &&
      module.network.name == "orders-cus-prod-spoke-vnet" &&
      module.resource_groups.group_names["network"] == "internal-apps-orders-cus-prod-network-rg" &&
      module.resource_groups.group_names["security"] == "internal-apps-orders-cus-prod-security-rg" &&
      toset(keys(output.subnet_ids)) == toset(["app", "private_endpoints"]) &&
      alltrue([for subnet in values(module.network.subnets) : !subnet.default_outbound_access_enabled && subnet.private_endpoint_network_policies == "Enabled"])
    )
    error_message = "The reusable blueprint must compose actual local modules, generated cus names, keyed RG/subnet contracts and private subnet defaults."
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
      module.peering[0].peerings.spoke_to_hub.remote_virtual_network_id == var.platform.hub_virtual_network_id &&
      module.peering[0].peerings.hub_to_spoke.remote_virtual_network_id == output.spoke_virtual_network_id &&
      module.peering[0].peerings.hub_to_spoke.allow_forwarded_traffic && !module.peering[0].peerings.spoke_to_hub.use_remote_gateways &&
      length(module.peering[0].private_dns_spoke_link_ids) == 0 &&
      module.private_dns_link.links.vault.resource_group_name == "dns" && !module.private_dns_link.links.vault.registration_enabled &&
      module.private_dns_link.links.vault.virtual_network_id == output.spoke_virtual_network_id
    )
    error_message = "Both peering directions and the central zone link must be wired through the correct subscription aliases without assuming gateway readiness."
  }
  assert {
    condition = (
      !module.key_vault.security_configuration.public_network_access_enabled && module.key_vault.security_configuration.purge_protection_enabled &&
      module.key_vault.role_assignments.reader-workload.principal_id == output.workload_identity.principal_id &&
      module.key_vault.role_assignments.reader-workload.scope == output.key_vault.id &&
      module.key_vault.role_assignments.reader-workload.role_definition_name == "Key Vault Secrets User" &&
      output.diagnostic_ownership.workspace_id == var.platform.log_analytics_workspace_id &&
      module.resource_groups.group_names.application == "internal-apps-orders-cus-prod-application-rg" &&
      module.application_insights.security_configuration.local_authentication_disabled &&
      module.application_insights.security_configuration.workspace_id == var.platform.log_analytics_workspace_id
    )
    error_message = "Every spoke requires a private dedicated vault, scoped workload identity, application RG, Entra-authenticated telemetry and central audit logs."
  }
}

run "nonproduction_uses_same_blueprint_without_weaker_controls" {
  command = plan
  variables { environment = "dev" }
  assert {
    condition = (module.network.name == "orders-cus-dev-spoke-vnet" && module.key_vault.name == "orders-cus-dev-vault" &&
      module.key_vault.security_configuration.purge_protection_enabled && !module.key_vault.security_configuration.public_network_access_enabled
    )
    error_message = "Non-production must change environment naming, not security guarantees."
  }
}

run "external_attachment_has_no_second_owner" {
  command = plan
  variables { manage_hub_attachment = false }
  assert {
    condition = (length(module.peering) == 0 && length(module.private_dns_link.ids) == 0 &&
      output.attachment_contract.owner == "central-attachment-workspace"
    )
    error_message = "Central attachment mode must not create either peering direction or duplicate the central DNS link."
  }
}

run "gateway_transit_is_an_explicit_paired_decision" {
  command = plan
  variables { gateway_transit_enabled = true }
  assert {
    condition = (module.peering[0].peerings.hub_to_spoke.allow_gateway_transit && module.peering[0].peerings.spoke_to_hub.use_remote_gateways &&
      !module.peering[0].peerings.spoke_to_hub.allow_gateway_transit && !module.peering[0].peerings.hub_to_spoke.use_remote_gateways
    )
    error_message = "Gateway flags must be paired in the supported direction, never enabled independently."
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
  expect_failures = [var.subnets]
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
  expect_failures = [var.subnets]
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
      module.application_insights.security_configuration.sampling_percentage == 100 &&
      output.environment_profile.alert_severity == 1 && output.environment_profile.alert_frequency == "PT1M" &&
      module.telemetry_access.assignments.workload.scope == module.application_insights.id &&
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
    condition = (module.application_insights.security_configuration.sampling_percentage == 20 && output.environment_profile.alert_frequency == "PT5M" &&
    output.environment_profile.alert_severity == 3 && module.key_vault.security_configuration.purge_protection_enabled)
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
      module.storage.data.security_configuration.replication_type == "ZRS" &&
      module.storage.data.security_configuration.delete_retention_days == 30 && module.storage.data.security_configuration.versioning_enabled &&
      !module.storage.data.security_configuration.public_network_access_enabled && !module.storage.data.security_configuration.shared_access_key_enabled &&
      module.storage.data.security_configuration.min_tls_version == "TLS1_2" &&
      module.storage_access.assignments.data.scope == module.storage.data.id &&
      module.storage_blob_diagnostics.data.target_resource_id == "${module.storage.data.id}/blobServices/default" &&
      module.storage_blob_diagnostics.data.destinations.log_analytics_workspace_id == var.platform.log_analytics_workspace_id &&
      length(module.storage_dns_link.ids) == 1 && length(module.storage_endpoints) == 1
    )
    error_message = "Production Blob storage must be zone-redundant, private, keyless, recoverable, correctly scoped and monitored at the Blob child service."
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
  variables { operations = { budget = { amount = 1000, start_date = "2026-10-01T00:00:00Z" } } }
  expect_failures = [var.operations]
}

run "rejects_unapproved_budget_placeholder" {
  command = plan
  variables { operations = { notification_emails = ["ops@example.com"], budget = { amount = 0, start_date = "2026-10-01T00:00:00Z" } } }
  expect_failures = [var.operations]
}

run "rejects_private_monitoring_without_ready_platform_path" {
  command = plan
  variables { monitoring = { internet_ingestion_enabled = false } }
  expect_failures = [var.monitoring]
}

run "nonproduction_storage_is_lower_cost_but_still_private" {
  command = apply
  variables {
    environment      = "dev"
    storage_accounts = { data = {} }
  }
  assert {
    condition = (module.storage.data.security_configuration.replication_type == "LRS" && module.storage.data.security_configuration.delete_retention_days == 7 &&
      !module.storage.data.security_configuration.public_network_access_enabled && !module.storage.data.security_configuration.shared_access_key_enabled &&
    length(module.storage_access.ids) == 0)
    error_message = "Non-production uses LRS/7-day recovery but retains private, keyless storage and no implicit data access."
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
    condition     = length(module.storage_dns_link.ids) == 0 && output.attachment_contract.storage_blob_private_dns_zone_id != null
    error_message = "The central owner receives the Blob zone attachment contract without a competing DNS link."
  }
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
      module.key_vault.private_endpoint_configuration.subnet_id == output.subnet_ids.private_endpoints &&
      module.key_vault.private_endpoint_configuration.target_resource_id == output.key_vault.id &&
      toset(module.key_vault.private_endpoint_configuration.subresource_names) == toset(["vault"]) &&
      toset(module.key_vault.private_endpoint_configuration.private_dns_zone_ids) == toset([var.platform.key_vault_private_dns_zone_id])
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
      module.key_vault.role_assignments.reader-workload.principal_id == output.workload_identity.principal_id &&
      module.key_vault.role_assignments.reader-workload.scope == output.key_vault.id &&
      module.key_vault.role_assignments.reader-workload.role_definition_name == "Key Vault Secrets User" &&
      module.telemetry_access.assignments.workload.principal_id == output.workload_identity.principal_id &&
      module.telemetry_access.assignments.workload.scope == module.application_insights.id &&
      module.telemetry_access.assignments.workload.role_definition_name == "Monitoring Metrics Publisher" && length(module.storage_access.ids) == 0
    )
    error_message = "IAM-06 must publish the workload UAMI, scope its service roles to owned resources and avoid implicit Owner/Contributor or unused storage access."
  }
}
