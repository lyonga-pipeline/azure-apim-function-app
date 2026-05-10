locals {
  name_prefix = "${var.application_name}-${var.environment}"
  common_tags = merge(var.tags, {
    application = var.application_name
    environment = var.environment
  })
}

module "resource_group" {
  source   = "../../azure-terraform/modules/resource-group"
  name     = try(var.resource_group.name, "${local.name_prefix}-rg")
  location = var.location
  tags     = merge(local.common_tags, try(var.resource_group.tags, {}))
}

module "log_analytics" {
  source              = "../../azure-terraform/modules/log-analytics"
  name                = try(var.log_analytics.name, "${local.name_prefix}-law")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = try(var.log_analytics.sku, null)
  retention_in_days   = try(var.log_analytics.retention_in_days, null)
  tags                = merge(local.common_tags, try(var.log_analytics.tags, {}))
}

module "application_insights" {
  source                        = "../../azure-terraform/modules/application-insights"
  name                          = try(var.application_insights.name, "${local.name_prefix}-appi")
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  application_type              = try(var.application_insights.application_type, null)
  workspace_id                  = module.log_analytics.id
  retention_in_days             = try(var.application_insights.retention_in_days, null)
  sampling_percentage           = try(var.application_insights.sampling_percentage, null)
  disable_ip_masking            = try(var.application_insights.disable_ip_masking, null)
  local_authentication_disabled = try(var.application_insights.local_authentication_disabled, null)
  tags                          = merge(local.common_tags, try(var.application_insights.tags, {}))
}

module "virtual_network" {
  source              = "../../azure-terraform/modules/virtual-network"
  name                = try(var.virtual_network.name, "${local.name_prefix}-vnet")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = var.virtual_network.address_space
  dns_servers         = try(var.virtual_network.dns_servers, null)
  subnets             = try(var.virtual_network.subnets, {})
  tags                = merge(local.common_tags, try(var.virtual_network.tags, {}))
}

module "route_table" {
  source                        = "../../azure-terraform/modules/route-table"
  name                          = try(var.route_table.name, "${local.name_prefix}-rt")
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  bgp_route_propagation_enabled = try(var.route_table.bgp_route_propagation_enabled, null)
  routes                        = try(var.route_table.routes, {})
  tags                          = merge(local.common_tags, try(var.route_table.tags, {}))
}

module "function_subnet_route_table_association" {
  source         = "../../azure-terraform/modules/subnet-route-table-association"
  subnet_id      = module.virtual_network.subnet_ids[var.function_app.integration_subnet_name]
  route_table_id = module.route_table.id
}

module "nat_public_ip" {
  source                  = "../../azure-terraform/modules/public-ip"
  name                    = try(var.nat_public_ip.name, "${local.name_prefix}-nat-pip")
  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  allocation_method       = try(var.nat_public_ip.allocation_method, null)
  sku                     = try(var.nat_public_ip.sku, null)
  sku_tier                = try(var.nat_public_ip.sku_tier, null)
  ip_version              = try(var.nat_public_ip.ip_version, null)
  idle_timeout_in_minutes = try(var.nat_public_ip.idle_timeout_in_minutes, null)
  zones                   = try(var.nat_public_ip.zones, [])
  tags                    = merge(local.common_tags, try(var.nat_public_ip.tags, {}))
}

module "nat_gateway" {
  source                  = "../../azure-terraform/modules/nat-gateway"
  name                    = try(var.nat_gateway.name, "${local.name_prefix}-nat")
  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  sku_name                = try(var.nat_gateway.sku_name, null)
  idle_timeout_in_minutes = try(var.nat_gateway.idle_timeout_in_minutes, null)
  zones                   = try(var.nat_gateway.zones, [])
  tags                    = merge(local.common_tags, try(var.nat_gateway.tags, {}))
}

module "nat_gateway_associations" {
  source                = "../../azure-terraform/modules/nat-gateway-associations"
  nat_gateway_id        = module.nat_gateway.id
  public_ip_address_ids = [module.nat_public_ip.id]
  subnet_ids = [
    module.virtual_network.subnet_ids[var.function_app.integration_subnet_name],
    module.virtual_network.subnet_ids[var.container_group.subnet_name],
  ]
}

module "private_dns_zones" {
  source = "../../azure-terraform/modules/private-dns-zone"
  zones  = var.private_dns_zones
  tags   = local.common_tags
}

module "private_dns_links" {
  source = "../../azure-terraform/modules/private-dns-vnet-link"
  links = {
    for key, value in var.private_dns_links :
    key => merge(value, {
      virtual_network_id = module.virtual_network.id
    })
  }
  tags = local.common_tags
}

module "key_vault" {
  source                        = "../../azure-terraform/modules/key-vault"
  name                          = try(var.key_vault.name, "${local.name_prefix}-kv")
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  tenant_id                     = var.tenant_id
  sku_name                      = try(var.key_vault.sku_name, null)
  enable_rbac_authorization     = try(var.key_vault.enable_rbac_authorization, null)
  public_network_access_enabled = try(var.key_vault.public_network_access_enabled, null)
  purge_protection_enabled      = try(var.key_vault.purge_protection_enabled, null)
  network_acls                  = try(var.key_vault.network_acls, {})
  contacts                      = try(var.key_vault.contacts, {})
  tags                          = merge(local.common_tags, try(var.key_vault.tags, {}))
}

module "key_vault_secrets" {
  source       = "../../azure-terraform/modules/key-vault-secret"
  key_vault_id = module.key_vault.id
  secrets      = var.key_vault_secrets
  tags         = local.common_tags
}

module "storage_account" {
  source                            = "../../azure-terraform/modules/storage-account"
  name                              = var.storage_account.name
  resource_group_name               = module.resource_group.name
  location                          = module.resource_group.location
  account_tier                      = try(var.storage_account.account_tier, null)
  account_replication_type          = try(var.storage_account.account_replication_type, null)
  account_kind                      = try(var.storage_account.account_kind, null)
  access_tier                       = try(var.storage_account.access_tier, null)
  min_tls_version                   = try(var.storage_account.min_tls_version, null)
  public_network_access_enabled     = try(var.storage_account.public_network_access_enabled, null)
  allow_nested_items_to_be_public   = try(var.storage_account.allow_nested_items_to_be_public, null)
  shared_access_key_enabled         = try(var.storage_account.shared_access_key_enabled, null)
  infrastructure_encryption_enabled = try(var.storage_account.infrastructure_encryption_enabled, null)
  identity                          = try(var.storage_account.identity, null)
  network_rules                     = try(var.storage_account.network_rules, null)
  queue_properties                  = try(var.storage_account.queue_properties, null)
  blob_properties                   = try(var.storage_account.blob_properties, null)
  tags                              = merge(local.common_tags, try(var.storage_account.tags, {}))
}

module "storage_containers" {
  source               = "../../azure-terraform/modules/storage-container"
  storage_account_name = module.storage_account.name
  containers           = var.storage_containers
}

module "storage_queues" {
  source               = "../../azure-terraform/modules/storage-queue"
  storage_account_name = module.storage_account.name
  queues               = var.storage_queues
}

module "storage_tables" {
  source               = "../../azure-terraform/modules/storage-table"
  storage_account_name = module.storage_account.name
  tables               = var.storage_tables
}

module "storage_shares" {
  source               = "../../azure-terraform/modules/storage-share"
  storage_account_name = module.storage_account.name
  shares               = var.storage_shares
}

module "app_service_plan" {
  source              = "../../azure-terraform/modules/app-service-plan"
  name                = try(var.app_service_plan.name, "${local.name_prefix}-plan")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  os_type             = var.app_service_plan.os_type
  sku_name            = var.app_service_plan.sku_name
  worker_count        = try(var.app_service_plan.worker_count, null)
  tags                = merge(local.common_tags, try(var.app_service_plan.tags, {}))
}

module "function_app" {
  source              = "../../azure-terraform/modules/function-app"
  name                = try(var.function_app.name, "${local.name_prefix}-func")
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  os_type             = var.function_app.os_type
  service_plan_id     = module.app_service_plan.id
  storage = merge(var.function_app.storage, {
    account_name          = module.storage_account.name
    uses_managed_identity = true
  })
  public_network_access_enabled = try(var.function_app.public_network_access_enabled, null)
  https_only                    = try(var.function_app.https_only, null)
  functions_extension_version   = try(var.function_app.functions_extension_version, null)
  enabled                       = try(var.function_app.enabled, null)
  builtin_logging_enabled       = try(var.function_app.builtin_logging_enabled, null)
  client_certificate_enabled    = try(var.function_app.client_certificate_enabled, null)
  client_certificate_mode       = try(var.function_app.client_certificate_mode, null)
  identity                      = try(var.function_app.identity, null)
  site_config = merge(
    try(var.function_app.site_config, {}),
    {
      application_insights_connection_string = module.application_insights.connection_string
    }
  )
  connection_strings = try(var.function_app.connection_strings, {})
  backup             = try(var.function_app.backup, null)
  sticky_settings    = try(var.function_app.sticky_settings, null)
  auth_settings_v2   = try(var.function_app.auth_settings_v2, null)
  app_settings = merge(
    try(var.function_app.app_settings, {}),
    {
      KEY_VAULT_URI                 = module.key_vault.vault_uri
      STORAGE_ACCOUNT_NAME          = module.storage_account.name
      APPINSIGHTS_CONNECTION_STRING = module.application_insights.connection_string
    }
  )
  tags = merge(local.common_tags, try(var.function_app.tags, {}))
}

module "function_app_slot" {
  source          = "../../azure-terraform/modules/function-app-slot"
  name            = try(var.function_app_slot.name, "staging")
  function_app_id = module.function_app.id
  os_type         = var.function_app_slot.os_type
  storage = merge(var.function_app_slot.storage, {
    account_name          = module.storage_account.name
    uses_managed_identity = true
  })
  public_network_access_enabled = try(var.function_app_slot.public_network_access_enabled, null)
  https_only                    = try(var.function_app_slot.https_only, null)
  enabled                       = try(var.function_app_slot.enabled, null)
  functions_extension_version   = try(var.function_app_slot.functions_extension_version, null)
  client_certificate_enabled    = try(var.function_app_slot.client_certificate_enabled, null)
  client_certificate_mode       = try(var.function_app_slot.client_certificate_mode, null)
  identity                      = try(var.function_app_slot.identity, null)
  site_config = merge(
    try(var.function_app_slot.site_config, {}),
    {
      application_insights_connection_string = module.application_insights.connection_string
    }
  )
  connection_strings = try(var.function_app_slot.connection_strings, {})
  app_settings       = try(var.function_app_slot.app_settings, {})
  tags               = merge(local.common_tags, try(var.function_app_slot.tags, {}))
}

module "function_app_vnet_integration" {
  source         = "../../azure-terraform/modules/app-service-vnet-integration"
  app_service_id = module.function_app.id
  subnet_id      = module.virtual_network.subnet_ids[var.function_app.integration_subnet_name]
}

module "container_group" {
  source                     = "../../azure-terraform/modules/container-agent"
  name                       = try(var.container_group.name, "${local.name_prefix}-aci")
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  os_type                    = try(var.container_group.os_type, null)
  ip_address_type            = try(var.container_group.ip_address_type, null)
  dns_name_label             = try(var.container_group.dns_name_label, null)
  subnet_ids                 = [module.virtual_network.subnet_ids[var.container_group.subnet_name]]
  restart_policy             = try(var.container_group.restart_policy, null)
  zones                      = try(var.container_group.zones, [])
  identity                   = try(var.container_group.identity, null)
  image_registry_credentials = try(var.container_group.image_registry_credentials, {})
  containers                 = var.container_group.containers
  exposed_ports              = try(var.container_group.exposed_ports, {})
  tags                       = merge(local.common_tags, try(var.container_group.tags, {}))
}

module "eventgrid_topic" {
  source                        = "../../azure-terraform/modules/eventgrid-topic"
  name                          = try(var.eventgrid_topic.name, "${local.name_prefix}-egt")
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  input_schema                  = try(var.eventgrid_topic.input_schema, null)
  public_network_access_enabled = try(var.eventgrid_topic.public_network_access_enabled, null)
  local_auth_enabled            = try(var.eventgrid_topic.local_auth_enabled, null)
  identity                      = try(var.eventgrid_topic.identity, null)
  inbound_ip_rules              = try(var.eventgrid_topic.inbound_ip_rules, {})
  tags                          = merge(local.common_tags, try(var.eventgrid_topic.tags, {}))
}

module "eventgrid_subscription" {
  source                               = "../../azure-terraform/modules/eventgrid-subscription"
  name                                 = try(var.eventgrid_subscription.name, "${local.name_prefix}-subscription")
  scope                                = module.eventgrid_topic.id
  included_event_types                 = try(var.eventgrid_subscription.included_event_types, [])
  event_delivery_schema                = try(var.eventgrid_subscription.event_delivery_schema, null)
  labels                               = try(var.eventgrid_subscription.labels, [])
  expiration_time_utc                  = try(var.eventgrid_subscription.expiration_time_utc, null)
  advanced_filtering_on_arrays_enabled = try(var.eventgrid_subscription.advanced_filtering_on_arrays_enabled, null)
  subject_filter                       = try(var.eventgrid_subscription.subject_filter, {})
  advanced_filter                      = try(var.eventgrid_subscription.advanced_filter, null)
  storage_queue_endpoint = {
    storage_account_id = module.storage_account.id
    queue_name         = var.eventgrid_subscription.storage_queue_name
  }
  dead_letter_destination = try(var.eventgrid_subscription.dead_letter_destination, null) == null ? null : {
    storage_account_id          = module.storage_account.id
    storage_blob_container_name = var.eventgrid_subscription.dead_letter_destination.storage_blob_container_name
  }
  retry_policy         = try(var.eventgrid_subscription.retry_policy, null)
  delivery_identity    = try(var.eventgrid_subscription.delivery_identity, null)
  dead_letter_identity = try(var.eventgrid_subscription.dead_letter_identity, null)
  delivery_properties  = try(var.eventgrid_subscription.delivery_properties, [])
}

module "function_app_private_endpoint" {
  source                     = "../../azure-terraform/modules/private-endpoint"
  name                       = try(var.function_app_private_endpoint.name, "${local.name_prefix}-func-pe")
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  subnet_id                  = module.virtual_network.subnet_ids[var.function_app_private_endpoint.subnet_name]
  private_service_connection = merge(var.function_app_private_endpoint.private_service_connection, { private_connection_resource_id = module.function_app.id })
  private_dns_zone_group     = try(var.function_app_private_endpoint.private_dns_zone_group, null)
  ip_configurations          = try(var.function_app_private_endpoint.ip_configurations, {})
  tags                       = merge(local.common_tags, try(var.function_app_private_endpoint.tags, {}))
}

module "key_vault_private_endpoint" {
  source                     = "../../azure-terraform/modules/private-endpoint"
  name                       = try(var.key_vault_private_endpoint.name, "${local.name_prefix}-kv-pe")
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  subnet_id                  = module.virtual_network.subnet_ids[var.key_vault_private_endpoint.subnet_name]
  private_service_connection = merge(var.key_vault_private_endpoint.private_service_connection, { private_connection_resource_id = module.key_vault.id })
  private_dns_zone_group     = try(var.key_vault_private_endpoint.private_dns_zone_group, null)
  ip_configurations          = try(var.key_vault_private_endpoint.ip_configurations, {})
  tags                       = merge(local.common_tags, try(var.key_vault_private_endpoint.tags, {}))
}

module "function_app_to_key_vault_role" {
  source = "../../azure-terraform/modules/role-assignments"
  assignments = {
    func-kv = {
      scope                = module.key_vault.id
      principal_id         = module.function_app.identity[0].principal_id
      role_definition_name = var.function_app_key_vault_role_name
      principal_type       = "ServicePrincipal"
    }
  }
}

module "function_app_to_storage_role" {
  source = "../../azure-terraform/modules/role-assignments"
  assignments = {
    func-storage = {
      scope                = module.storage_account.id
      principal_id         = module.function_app.identity[0].principal_id
      role_definition_name = var.function_app_storage_role_name
      principal_type       = "ServicePrincipal"
    }
  }
}

module "function_app_diagnostics" {
  source                     = "../../azure-terraform/modules/diagnostic-settings"
  name                       = try(var.function_app_diagnostics.name, "${local.name_prefix}-func-diag")
  target_resource_id         = module.function_app.id
  log_analytics_workspace_id = module.log_analytics.id
  logs                       = try(var.function_app_diagnostics.logs, {})
  metrics                    = try(var.function_app_diagnostics.metrics, {})
}

module "eventgrid_diagnostics" {
  source                     = "../../azure-terraform/modules/diagnostic-settings"
  name                       = try(var.eventgrid_diagnostics.name, "${local.name_prefix}-egt-diag")
  target_resource_id         = module.eventgrid_topic.id
  log_analytics_workspace_id = module.log_analytics.id
  logs                       = try(var.eventgrid_diagnostics.logs, {})
  metrics                    = try(var.eventgrid_diagnostics.metrics, {})
}
