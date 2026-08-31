module "tags" {
  source = "../../modules/terraform-azurerm-compeer-platform-tags"

  environment         = var.environment
  application         = var.platform_tags.application
  business_owner      = var.platform_tags.business_owner
  source_repo         = var.platform_tags.source_repo
  terraform_workspace = var.platform_tags.terraform_workspace
  recovery_tier       = var.platform_tags.recovery_tier
  cost_center         = var.platform_tags.cost_center
  data_classification = var.platform_tags.data_classification
  compliance_boundary = var.platform_tags.compliance_boundary
  additional_tags     = var.platform_tags.additional_tags
}

module "resource_group" {
  source = "../../modules/terraform-azurerm-compeer-resource-group"

  name     = var.resource_group.name
  location = var.location
  tags     = module.tags.tags
}

module "log_analytics" {
  source = "../../modules/terraform-azurerm-compeer-log-analytics"

  log_analytics_workspace_name            = var.log_analytics.name
  resource_group_name                     = module.resource_group.name
  location                                = module.resource_group.location
  log_analytics_sku                       = var.log_analytics.sku
  log_analytics_retention_in_days         = var.log_analytics.retention_in_days
  log_analytics_daily_quota_gb            = coalesce(try(var.log_analytics.daily_quota_gb, null), -1)
  allow_resource_only_permissions         = try(var.log_analytics.allow_resource_only_permissions, null)
  cmk_for_query_forced                    = try(var.log_analytics.cmk_for_query_forced, null)
  data_collection_rule_id                 = try(var.log_analytics.data_collection_rule_id, null)
  immediate_data_purge_on_30_days_enabled = try(var.log_analytics.immediate_data_purge_on_30_days_enabled, null)
  internet_ingestion_enabled              = try(var.log_analytics.internet_ingestion_enabled, null)
  internet_query_enabled                  = try(var.log_analytics.internet_query_enabled, null)
  local_authentication_disabled           = try(var.log_analytics.local_authentication_disabled, null)
  reservation_capacity_in_gb_per_day      = try(var.log_analytics.reservation_capacity_in_gb_per_day, null)
  identity                                = try(var.log_analytics.identity, null)
  timeouts                                = try(var.log_analytics.timeouts, {})
  tags                                    = module.tags.tags
}

module "action_group" {
  source = "../../modules/terraform-azurerm-compeer-action-group"

  name                = var.action_group.name
  resource_group_name = module.resource_group.name
  short_name          = var.action_group.short_name
  enabled             = try(var.action_group.enabled, true)
  receivers           = var.action_group.receivers
  timeouts            = try(var.action_group.timeouts, {})
  tags                = module.tags.tags
}

module "platform_storage_accounts" {
  source   = "../../modules/terraform-azurerm-compeer-storage-account"
  for_each = var.platform_storage_accounts

  name                              = each.value.name
  resource_group_name               = module.resource_group.name
  location                          = module.resource_group.location
  account_tier                      = each.value.account_tier
  account_replication_type          = each.value.account_replication_type
  account_kind                      = each.value.account_kind
  access_tier                       = each.value.access_tier
  edge_zone                         = try(each.value.edge_zone, null)
  min_tls_version                   = each.value.min_tls_version
  https_traffic_only_enabled        = try(each.value.https_traffic_only_enabled, true)
  public_network_access_enabled     = each.value.public_network_access_enabled
  allow_nested_items_to_be_public   = each.value.allow_nested_items_to_be_public
  shared_access_key_enabled         = each.value.shared_access_key_enabled
  infrastructure_encryption_enabled = each.value.infrastructure_encryption_enabled
  is_hns_enabled                    = each.value.is_hns_enabled
  sftp_enabled                      = each.value.sftp_enabled
  local_user_enabled                = each.value.local_user_enabled
  nfsv3_enabled                     = each.value.nfsv3_enabled
  large_file_share_enabled          = each.value.large_file_share_enabled
  cross_tenant_replication_enabled  = each.value.cross_tenant_replication_enabled
  default_to_oauth_authentication   = each.value.default_to_oauth_authentication
  allowed_copy_scope                = try(each.value.allowed_copy_scope, null)
  dns_endpoint_type                 = try(each.value.dns_endpoint_type, null)
  queue_encryption_key_type         = try(each.value.queue_encryption_key_type, null)
  table_encryption_key_type         = try(each.value.table_encryption_key_type, null)
  provisioned_billing_model_version = try(each.value.provisioned_billing_model_version, null)
  identity                          = try(each.value.identity, null)
  customer_managed_key              = try(each.value.customer_managed_key, null)
  network_rules                     = try(each.value.network_rules, null)
  blob_properties                   = try(each.value.blob_properties, null)
  queue_properties                  = try(each.value.queue_properties, null)
  share_properties                  = try(each.value.share_properties, null)
  azure_files_authentication        = try(each.value.azure_files_authentication, null)
  custom_domain                     = try(each.value.custom_domain, null)
  immutability_policy               = try(each.value.immutability_policy, null)
  routing                           = try(each.value.routing, null)
  sas_policy                        = try(each.value.sas_policy, null)
  static_website                    = try(each.value.static_website, null)
  timeouts                          = try(each.value.timeouts, {})
  tags                              = module.tags.tags
}

module "platform_key_vaults" {
  source   = "../../modules/terraform-azurerm-compeer-keyvault"
  for_each = var.platform_key_vaults

  name                            = each.value.name
  resource_group_name             = module.resource_group.name
  location                        = module.resource_group.location
  sku_name                        = try(each.value.sku_name, "standard")
  tenant_id                       = try(each.value.tenant_id, null)
  access_policies                 = try(each.value.access_policies, [])
  access_policies_by_key          = try(each.value.access_policies_by_key, {})
  rbac_authorization_enabled      = try(each.value.rbac_authorization_enabled, true)
  enabled_for_deployment          = try(each.value.enabled_for_deployment, false)
  enabled_for_disk_encryption     = try(each.value.enabled_for_disk_encryption, false)
  enabled_for_template_deployment = try(each.value.enabled_for_template_deployment, false)
  network_acls                    = try(each.value.network_acls, null)
  purge_protection_enabled        = try(each.value.purge_protection_enabled, true)
  public_network_access_enabled   = try(each.value.public_network_access_enabled, false)
  soft_delete_retention_days      = try(each.value.soft_delete_retention_days, 90)
  contacts                        = try(each.value.contacts, [])
  timeouts                        = try(each.value.timeouts, {})
  tags                            = module.tags.tags
}

module "recovery_services_vaults" {
  source   = "../../modules/terraform-azurerm-compeer-recovery-services-vault"
  for_each = var.recovery_services_vaults

  name                               = each.value.name
  resource_group_name                = module.resource_group.name
  location                           = module.resource_group.location
  sku                                = each.value.sku
  soft_delete_enabled                = each.value.soft_delete_enabled
  storage_mode_type                  = each.value.storage_mode_type
  public_network_access_enabled      = try(each.value.public_network_access_enabled, null)
  immutability                       = try(each.value.immutability, null)
  cross_region_restore_enabled       = try(each.value.cross_region_restore_enabled, null)
  classic_vmware_replication_enabled = try(each.value.classic_vmware_replication_enabled, null)
  identity                           = try(each.value.identity, null)
  encryption                         = try(each.value.encryption, null)
  monitoring                         = try(each.value.monitoring, null)
  timeouts                           = try(each.value.timeouts, {})
  tags                               = module.tags.tags
}

module "data_collection_endpoints" {
  source   = "../../modules/terraform-azurerm-compeer-monitor-data-collection-endpoint"
  for_each = var.data_collection_endpoints

  name                          = each.value.name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  kind                          = try(each.value.kind, null)
  description                   = try(each.value.description, null)
  public_network_access_enabled = try(each.value.public_network_access_enabled, null)
  timeouts                      = try(each.value.timeouts, {})
  tags                          = module.tags.tags
}

locals {
  subscription_scope = "/subscriptions/${var.subscription_id}"
  sentinel_enabled   = coalesce(try(var.sentinel.enabled, null), false)
  log_analytics_default_contributor_role_definition_name = coalesce(
    try(var.log_analytics.contributor_role_definition_name, null),
    "Log Analytics Contributor"
  )
  log_analytics_contributor_assignments_from_list = {
    for principal_id in try(var.log_analytics.contributors, []) : "principal:${principal_id}" => {
      scope                = module.log_analytics.id
      principal_id         = principal_id
      role_definition_name = local.log_analytics_default_contributor_role_definition_name
    }
  }
  log_analytics_contributor_assignments_by_key = {
    for key, assignment in try(var.log_analytics.contributors_by_key, {}) : key => merge(assignment, {
      scope = module.log_analytics.id
      role_definition_name = try(assignment.role_definition_id, null) == null ? coalesce(
        try(assignment.role_definition_name, null),
        local.log_analytics_default_contributor_role_definition_name
      ) : null
      role_definition_id = try(assignment.role_definition_id, null)
    })
  }
  log_analytics_contributor_role_assignments = merge(
    local.log_analytics_contributor_assignments_from_list,
    local.log_analytics_contributor_assignments_by_key
  )
  defender_soc_posture = {
    enabled                       = coalesce(try(var.defender_soc_posture.enabled, null), false)
    defender_standard_enabled     = coalesce(try(var.defender_soc_posture.defender_standard_enabled, null), false)
    sentinel_enabled              = coalesce(try(var.defender_soc_posture.sentinel_enabled, null), false)
    data_collection_rules_enabled = coalesce(try(var.defender_soc_posture.data_collection_rules_enabled, null), false)
    security_contact_enabled      = coalesce(try(var.defender_soc_posture.security_contact_enabled, null), false)
    notes                         = try(var.defender_soc_posture.notes, null)
  }

  platform_scope_ids = merge(
    {
      subscription   = local.subscription_scope
      resource_group = module.resource_group.id
      log_analytics  = module.log_analytics.id
      action_group   = module.action_group.id
    },
    {
      for key, value in module.platform_storage_accounts : "storage_account:${key}" => value.id
    },
    {
      for key, value in module.platform_key_vaults : "key_vault:${key}" => value.id
    },
    {
      for key, value in module.recovery_services_vaults : "recovery_vault:${key}" => value.id
    },
    {
      for key, value in module.data_collection_endpoints : "data_collection_endpoint:${key}" => value.id
    },
    {
      for key, value in module.data_collection_rules : "data_collection_rule:${key}" => value.id
    },
    var.additional_lock_scopes
  )

  data_collection_rule_inputs = {
    for key, rule in var.data_collection_rules : key => merge(rule, {
      data_collection_endpoint_id = coalesce(try(rule.data_collection_endpoint_id, null), try(module.data_collection_endpoints[rule.data_collection_endpoint_key].id, null))
      destinations = merge(try(rule.destinations, {}), {
        log_analytics = {
          for destination_key, destination in try(rule.destinations.log_analytics, {}) : destination_key => merge(destination, {
            workspace_resource_id = coalesce(try(destination.workspace_resource_id, null), module.log_analytics.id)
          })
        }
      })
    })
  }

  platform_storage_diagnostic_inputs = {
    for key, diagnostic in var.platform_storage_diagnostics : key => {
      name                           = diagnostic.name
      target_resource_id             = coalesce(try(diagnostic.target_resource_id, null), try(module.platform_storage_accounts[diagnostic.storage_account_key].id, null))
      log_analytics_workspace_id     = coalesce(try(diagnostic.log_analytics_workspace_id, null), module.log_analytics.id)
      log_analytics_destination_type = try(diagnostic.log_analytics_destination_type, null)
      storage_account_id             = try(diagnostic.archive_storage_account_id, null)
      eventhub_authorization_rule_id = try(
        diagnostic.eventhub_authorization_rule_id,
        null
      )
      eventhub_name       = try(diagnostic.eventhub_name, null)
      partner_solution_id = try(diagnostic.partner_solution_id, null)
      logs                = try(diagnostic.logs, {})
      metrics             = try(diagnostic.metrics, {})
    }
  }

  platform_key_vault_diagnostic_inputs = {
    for key, diagnostic in var.platform_key_vault_diagnostics : key => {
      name                           = diagnostic.name
      target_resource_id             = coalesce(try(diagnostic.target_resource_id, null), try(module.platform_key_vaults[diagnostic.key_vault_key].id, null))
      log_analytics_workspace_id     = coalesce(try(diagnostic.log_analytics_workspace_id, null), module.log_analytics.id)
      log_analytics_destination_type = try(diagnostic.log_analytics_destination_type, null)
      storage_account_id             = try(diagnostic.archive_storage_account_id, null)
      eventhub_authorization_rule_id = try(
        diagnostic.eventhub_authorization_rule_id,
        null
      )
      eventhub_name       = try(diagnostic.eventhub_name, null)
      partner_solution_id = try(diagnostic.partner_solution_id, null)
      logs                = try(diagnostic.logs, {})
      metrics             = try(diagnostic.metrics, {})
    }
  }

  recovery_services_vault_diagnostic_inputs = {
    for key, diagnostic in var.recovery_services_vault_diagnostics : key => {
      name                           = diagnostic.name
      target_resource_id             = coalesce(try(diagnostic.target_resource_id, null), try(module.recovery_services_vaults[diagnostic.recovery_services_vault_key].id, null))
      log_analytics_workspace_id     = coalesce(try(diagnostic.log_analytics_workspace_id, null), module.log_analytics.id)
      log_analytics_destination_type = try(diagnostic.log_analytics_destination_type, null)
      storage_account_id             = try(diagnostic.archive_storage_account_id, null)
      eventhub_authorization_rule_id = try(
        diagnostic.eventhub_authorization_rule_id,
        null
      )
      eventhub_name       = try(diagnostic.eventhub_name, null)
      partner_solution_id = try(diagnostic.partner_solution_id, null)
      logs                = try(diagnostic.logs, {})
      metrics             = try(diagnostic.metrics, {})
    }
  }

  role_assignment_inputs = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      scope = coalesce(
        try(assignment.scope, null),
        try(local.platform_scope_ids[assignment.scope_key], null)
      )
    })
  }
}

resource "azurerm_resource_provider_registration" "this" {
  for_each = var.resource_provider_registrations

  name = each.key

  dynamic "feature" {
    for_each = try(each.value.features, {})
    content {
      name       = feature.key
      registered = feature.value.registered
    }
  }
}

module "role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.role_assignment_inputs
}

module "log_analytics_contributor_role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.log_analytics_contributor_role_assignments
}

resource "azurerm_security_center_workspace" "log_analytics" {
  for_each = toset(try(var.log_analytics.security_center_subscriptions, []))

  scope        = "/subscriptions/${each.value}"
  workspace_id = module.log_analytics.id
}

module "platform_storage_diagnostics" {
  source   = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  for_each = local.platform_storage_diagnostic_inputs

  name                           = each.value.name
  target_resource_id             = each.value.target_resource_id
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  log_analytics_destination_type = try(each.value.log_analytics_destination_type, null)
  storage_account_id             = each.value.storage_account_id
  eventhub_authorization_rule_id = try(
    each.value.eventhub_authorization_rule_id,
    null
  )
  eventhub_name       = try(each.value.eventhub_name, null)
  partner_solution_id = try(each.value.partner_solution_id, null)
  logs                = each.value.logs
  metrics             = each.value.metrics
}

module "platform_storage_private_endpoints" {
  source   = "../../modules/terraform-azurerm-compeer-private-endpoint"
  for_each = var.platform_storage_private_endpoints

  name                          = each.value.name
  custom_network_interface_name = try(each.value.custom_network_interface_name, null)
  resource_group_name           = coalesce(try(each.value.resource_group_name, null), module.resource_group.name)
  location                      = coalesce(try(each.value.location, null), module.resource_group.location)
  edge_zone                     = try(each.value.edge_zone, null)
  subnet_id                     = each.value.subnet_id
  private_service_connections = [
    {
      name                           = coalesce(try(each.value.private_service_connection_name, null), "${each.value.name}-psc")
      is_manual_connection           = try(each.value.is_manual_connection, false)
      private_connection_resource_id = coalesce(try(each.value.private_connection_resource_id, null), try(module.platform_storage_accounts[each.value.storage_account_key].id, null))
      subresource_names              = [each.value.subresource_name]
      request_message                = try(each.value.request_message, null)
    }
  ]
  private_dns_zone_group = length(try(each.value.private_dns_zone_ids, [])) == 0 ? [] : [
    {
      name                 = coalesce(try(each.value.private_dns_zone_group_name, null), "default")
      private_dns_zone_ids = each.value.private_dns_zone_ids
    }
  ]
  ip_configurations = try(each.value.ip_configurations, [])
  timeouts          = try(each.value.timeouts, {})
  tags              = module.tags.tags
}

module "platform_key_vault_diagnostics" {
  source   = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  for_each = local.platform_key_vault_diagnostic_inputs

  name                           = each.value.name
  target_resource_id             = each.value.target_resource_id
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  log_analytics_destination_type = try(each.value.log_analytics_destination_type, null)
  storage_account_id             = each.value.storage_account_id
  eventhub_authorization_rule_id = try(
    each.value.eventhub_authorization_rule_id,
    null
  )
  eventhub_name       = try(each.value.eventhub_name, null)
  partner_solution_id = try(each.value.partner_solution_id, null)
  logs                = each.value.logs
  metrics             = each.value.metrics
}

module "platform_key_vault_private_endpoints" {
  source   = "../../modules/terraform-azurerm-compeer-private-endpoint"
  for_each = var.platform_key_vault_private_endpoints

  name                          = each.value.name
  custom_network_interface_name = try(each.value.custom_network_interface_name, null)
  resource_group_name           = coalesce(try(each.value.resource_group_name, null), module.resource_group.name)
  location                      = coalesce(try(each.value.location, null), module.resource_group.location)
  edge_zone                     = try(each.value.edge_zone, null)
  subnet_id                     = each.value.subnet_id
  private_service_connections = [
    {
      name                           = coalesce(try(each.value.private_service_connection_name, null), "${each.value.name}-psc")
      is_manual_connection           = try(each.value.is_manual_connection, false)
      private_connection_resource_id = coalesce(try(each.value.private_connection_resource_id, null), try(module.platform_key_vaults[each.value.key_vault_key].id, null))
      subresource_names              = [try(each.value.subresource_name, "vault")]
      request_message                = try(each.value.request_message, null)
    }
  ]
  private_dns_zone_group = length(try(each.value.private_dns_zone_ids, [])) == 0 ? [] : [
    {
      name                 = coalesce(try(each.value.private_dns_zone_group_name, null), "default")
      private_dns_zone_ids = each.value.private_dns_zone_ids
    }
  ]
  ip_configurations = try(each.value.ip_configurations, [])
  timeouts          = try(each.value.timeouts, {})
  tags              = module.tags.tags
}

module "recovery_services_vault_diagnostics" {
  source   = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  for_each = local.recovery_services_vault_diagnostic_inputs

  name                           = each.value.name
  target_resource_id             = each.value.target_resource_id
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  log_analytics_destination_type = try(each.value.log_analytics_destination_type, null)
  storage_account_id             = each.value.storage_account_id
  eventhub_authorization_rule_id = try(
    each.value.eventhub_authorization_rule_id,
    null
  )
  eventhub_name       = try(each.value.eventhub_name, null)
  partner_solution_id = try(each.value.partner_solution_id, null)
  logs                = each.value.logs
  metrics             = each.value.metrics
}

module "data_collection_rules" {
  source   = "../../modules/terraform-azurerm-compeer-monitor-data-collection-rule"
  for_each = local.data_collection_rule_inputs

  name                        = each.value.name
  resource_group_name         = module.resource_group.name
  location                    = module.resource_group.location
  description                 = try(each.value.description, null)
  kind                        = try(each.value.kind, null)
  data_collection_endpoint_id = try(each.value.data_collection_endpoint_id, null)
  destinations                = each.value.destinations
  data_flows                  = each.value.data_flows
  data_sources                = try(each.value.data_sources, {})
  stream_declarations         = try(each.value.stream_declarations, {})
  identity                    = try(each.value.identity, null)
  timeouts                    = try(each.value.timeouts, {})
  tags                        = module.tags.tags
}

module "data_collection_rule_associations" {
  source   = "../../modules/terraform-azurerm-compeer-monitor-data-collection-rule-association"
  for_each = var.data_collection_rule_associations

  name               = try(each.value.name, null)
  target_resource_id = coalesce(try(each.value.target_resource_id, null), try(local.platform_scope_ids[each.value.target_key], null))
  data_collection_rule_id = coalesce(
    try(each.value.data_collection_rule_id, null),
    try(module.data_collection_rules[each.value.data_collection_rule_key].id, null)
  )
  data_collection_endpoint_id = coalesce(
    try(each.value.data_collection_endpoint_id, null),
    try(module.data_collection_endpoints[each.value.data_collection_endpoint_key].id, null)
  )
  description = try(each.value.description, null)
}

module "sentinel" {
  source = "../../modules/terraform-azurerm-compeer-sentinel"

  enabled                    = local.sentinel_enabled
  log_analytics_workspace_id = module.log_analytics.id
  approved_data_connectors   = try(var.sentinel.approved_data_connectors, {})
}

resource "azurerm_monitor_diagnostic_setting" "subscription_activity_log" {
  count = var.subscription_activity_log_diagnostics == null ? 0 : 1

  name                       = var.subscription_activity_log_diagnostics.name
  target_resource_id         = local.subscription_scope
  log_analytics_workspace_id = module.log_analytics.id
  storage_account_id         = try(var.subscription_activity_log_diagnostics.storage_account_id, null)
  eventhub_authorization_rule_id = try(
    var.subscription_activity_log_diagnostics.eventhub_authorization_rule_id,
    null
  )
  eventhub_name = try(var.subscription_activity_log_diagnostics.eventhub_name, null)

  dynamic "enabled_log" {
    for_each = var.subscription_activity_log_diagnostics.logs
    content {
      category = enabled_log.value.category
    }
  }
}

resource "azurerm_monitor_aad_diagnostic_setting" "entra" {
  count = var.entra_diagnostic_settings == null ? 0 : 1

  name                           = var.entra_diagnostic_settings.name
  log_analytics_workspace_id     = module.log_analytics.id
  storage_account_id             = try(var.entra_diagnostic_settings.storage_account_id, null)
  eventhub_authorization_rule_id = try(var.entra_diagnostic_settings.eventhub_authorization_rule_id, null)
  eventhub_name                  = try(var.entra_diagnostic_settings.eventhub_name, null)

  dynamic "enabled_log" {
    for_each = var.entra_diagnostic_settings.logs
    content {
      category = enabled_log.value.category
    }
  }
}

resource "azurerm_consumption_budget_subscription" "this" {
  for_each = var.subscription_budgets

  name            = each.key
  subscription_id = local.subscription_scope
  amount          = each.value.amount
  time_grain      = each.value.time_grain

  time_period {
    start_date = each.value.time_period.start_date
    end_date   = try(each.value.time_period.end_date, null)
  }

  dynamic "notification" {
    for_each = each.value.notifications
    content {
      enabled        = try(notification.value.enabled, true)
      threshold      = notification.value.threshold
      operator       = notification.value.operator
      threshold_type = try(notification.value.threshold_type, "Actual")
      contact_emails = try(notification.value.contact_emails, null)
      contact_groups = try(notification.value.contact_groups, null)
      contact_roles  = try(notification.value.contact_roles, null)
    }
  }
}

resource "azurerm_management_lock" "this" {
  for_each = var.management_locks

  name       = each.value.name
  scope      = coalesce(try(each.value.scope, null), try(local.platform_scope_ids[each.value.scope_key], null))
  lock_level = each.value.lock_level
  notes      = try(each.value.notes, null)
}

resource "azurerm_security_center_subscription_pricing" "this" {
  for_each = var.defender_plans

  resource_type = each.value.resource_type
  tier          = each.value.tier
  subplan       = try(each.value.subplan, null)

  dynamic "extension" {
    for_each = try(each.value.extensions, {})
    content {
      name                            = extension.value.name
      additional_extension_properties = try(extension.value.additional_extension_properties, null)
    }
  }
}

resource "azurerm_security_center_contact" "this" {
  count = var.security_contact == null ? 0 : 1

  name                = try(var.security_contact.name, "default")
  email               = var.security_contact.email
  phone               = try(var.security_contact.phone, null)
  alert_notifications = try(var.security_contact.alert_notifications, true)
  alerts_to_admins    = try(var.security_contact.alerts_to_admins, true)
}

resource "azurerm_security_center_setting" "this" {
  for_each = var.security_center_settings

  setting_name = each.key
  enabled      = each.value.enabled
}

resource "terraform_data" "defender_soc_posture_contract" {
  input = {
    enabled                       = local.defender_soc_posture.enabled
    defender_standard_enabled     = local.defender_soc_posture.defender_standard_enabled
    sentinel_enabled              = local.defender_soc_posture.sentinel_enabled
    data_collection_rules_enabled = local.defender_soc_posture.data_collection_rules_enabled
    security_contact_enabled      = local.defender_soc_posture.security_contact_enabled
    defender_plan_count           = length(var.defender_plans)
    security_contact_configured   = var.security_contact != null
    notes                         = local.defender_soc_posture.notes
  }

  lifecycle {
    precondition {
      condition = (
        !local.defender_soc_posture.defender_standard_enabled ||
        length(var.defender_plans) > 0
      )
      error_message = "Defender Standard posture cannot be marked enabled unless defender_plans contains the approved Standard plan map."
    }

    precondition {
      condition = (
        !local.defender_soc_posture.security_contact_enabled ||
        var.security_contact != null
      )
      error_message = "Security contact posture cannot be marked enabled unless security_contact is configured."
    }
  }
}
