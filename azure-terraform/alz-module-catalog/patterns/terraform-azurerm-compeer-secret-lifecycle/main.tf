locals {
  apps            = { worker = var.names.worker, scheduler = var.names.scheduler }
  vault_roles     = { for key, vault in var.vaults : key => vault.id }
  storage_targets = { for key, asset in var.assets : key => asset.target["resource_id"] if asset.adapter == "storage_dual_key" }
  endpoints = {
    host_blob  = { id = azurerm_storage_account.host.id, group = "blob", dns = "blob" }
    host_queue = { id = azurerm_storage_account.host.id, group = "queue", dns = "queue" }
    host_table = { id = azurerm_storage_account.host.id, group = "table", dns = "table" }
    state_blob = { id = azurerm_storage_account.state.id, group = "blob", dns = "blob" }
    bus        = { id = azurerm_servicebus_namespace.rotation.id, group = "namespace", dns = "servicebus" }
    worker     = { id = azurerm_linux_function_app.app["worker"].id, group = "sites", dns = "sites" }
    scheduler  = { id = azurerm_linux_function_app.app["scheduler"].id, group = "sites", dns = "sites" }
  }
}
resource "terraform_data" "contract" {
  lifecycle {
    precondition {
      condition     = var.integration_subnet_id != var.private_endpoint_subnet_id
      error_message = "Function integration and private endpoints require separate subnets."
    }
    precondition {
      condition     = var.dns_owned_by_policy || alltrue([for key in ["blob", "queue", "table", "servicebus", "sites"] : contains(keys(var.private_dns_zone_ids), key)])
      error_message = "Supply all private DNS zones or explicitly confirm central DNS-zone-group policy ownership."
    }
    precondition {
      condition = alltrue([for asset in values(var.assets) :
        asset.environment == var.environment && anytrue([for vault in values(var.vaults) : lower(vault.id) == lower(asset.vault_id) && vault.url == asset.vault_url])
      ])
      error_message = "Assets must belong to this environment and match an explicitly enrolled vault ID/URL."
    }
  }
}
resource "azurerm_resource_group" "rotation" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
resource "azurerm_user_assigned_identity" "app" {
  for_each            = local.apps
  name                = "${each.value}-mi"
  location            = var.location
  resource_group_name = azurerm_resource_group.rotation.name
  tags                = var.tags
}
resource "azurerm_storage_account" "host" {
  name                            = var.names.host_storage
  resource_group_name             = azurerm_resource_group.rotation.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  default_to_oauth_authentication = true
  blob_properties { versioning_enabled = true }
  tags = var.tags
}
resource "azurerm_storage_account" "state" {
  name                            = var.names.state_storage
  resource_group_name             = azurerm_resource_group.rotation.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false
  public_network_access_enabled   = var.event_delivery_exception_approved
  allow_nested_items_to_be_public = false
  default_to_oauth_authentication = true
  network_rules {
    default_action = "Deny"
    bypass         = var.event_delivery_exception_approved ? ["AzureServices"] : ["None"]
  }
  blob_properties {
    versioning_enabled = true
    delete_retention_policy { days = 30 }
    container_delete_retention_policy { days = 30 }
  }
  tags = var.tags
}
resource "azurerm_storage_container" "state" {
  for_each              = toset(["execution", "event-deadletters"])
  name                  = each.value
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}
resource "azurerm_servicebus_namespace" "rotation" {
  name                          = var.names.service_bus
  resource_group_name           = azurerm_resource_group.rotation.name
  location                      = var.location
  sku                           = "Premium"
  capacity                      = 1
  premium_messaging_partitions  = 1
  local_auth_enabled            = false
  public_network_access_enabled = var.event_delivery_exception_approved
  minimum_tls_version           = "1.2"
  network_rule_set {
    default_action                = "Deny"
    trusted_services_allowed      = var.event_delivery_exception_approved
    public_network_access_enabled = var.event_delivery_exception_approved
  }
  tags = var.tags
}
resource "azurerm_servicebus_queue" "rotation" {
  for_each                                = toset(["rotation-work", "vault-events"])
  name                                    = each.value
  namespace_id                            = azurerm_servicebus_namespace.rotation.id
  requires_duplicate_detection            = true
  duplicate_detection_history_time_window = "PT10M"
  lock_duration                           = "PT5M"
  max_delivery_count                      = 5
  dead_lettering_on_message_expiration    = true
  default_message_ttl                     = "P7D"
}
resource "azurerm_role_assignment" "host_blob" {
  for_each             = local.apps
  scope                = azurerm_storage_account.host.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.app[each.key].principal_id
}
resource "azurerm_role_assignment" "host_queue" {
  for_each             = local.apps
  scope                = azurerm_storage_account.host.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_user_assigned_identity.app[each.key].principal_id
}
resource "azurerm_role_assignment" "metadata" {
  for_each             = { worker = "Storage Blob Data Contributor", scheduler = "Storage Blob Data Reader" }
  scope                = "${azurerm_storage_account.state.id}/blobServices/default/containers/execution"
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.app[each.key].principal_id
  depends_on           = [azurerm_storage_container.state]
}
resource "azurerm_role_assignment" "sender" {
  for_each             = local.apps
  scope                = azurerm_servicebus_queue.rotation["rotation-work"].id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_user_assigned_identity.app[each.key].principal_id
}
resource "azurerm_role_assignment" "receiver" {
  for_each             = azurerm_servicebus_queue.rotation
  scope                = each.value.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_user_assigned_identity.app["worker"].principal_id
}
resource "azurerm_role_assignment" "vault" {
  for_each             = local.vault_roles
  scope                = each.value
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_user_assigned_identity.app["worker"].principal_id
}
resource "azurerm_role_assignment" "vault_metadata" {
  for_each             = local.vault_roles
  scope                = each.value
  role_definition_name = "Key Vault Reader"
  principal_id         = azurerm_user_assigned_identity.app["scheduler"].principal_id
}
resource "azurerm_role_assignment" "storage_keys" {
  for_each             = local.storage_targets
  scope                = each.value
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = azurerm_user_assigned_identity.app["worker"].principal_id
}
resource "azurerm_service_plan" "rotation" {
  name                = var.names.plan
  location            = var.location
  resource_group_name = azurerm_resource_group.rotation.name
  os_type             = "Linux"
  # Dedicated hosting avoids the Azure Files connection-string requirement of
  # Elastic Premium. Always-on private workers still use identity-based storage.
  sku_name = "P1v3"
  tags     = var.tags
}
resource "azurerm_application_insights" "rotation" {
  name                         = "${var.names.worker}-ai"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rotation.name
  workspace_id                 = var.log_analytics_workspace_id
  application_type             = "web"
  local_authentication_enabled = false
  tags                         = var.tags
}
resource "azurerm_role_assignment" "telemetry" {
  for_each             = local.apps
  scope                = azurerm_application_insights.rotation.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_user_assigned_identity.app[each.key].principal_id
}
resource "azurerm_linux_function_app" "app" {
  for_each                                       = local.apps
  name                                           = each.value
  location                                       = var.location
  resource_group_name                            = azurerm_resource_group.rotation.name
  service_plan_id                                = azurerm_service_plan.rotation.id
  storage_account_name                           = azurerm_storage_account.host.name
  storage_uses_managed_identity                  = true
  virtual_network_subnet_id                      = var.integration_subnet_id
  public_network_access_enabled                  = false
  https_only                                     = true
  functions_extension_version                    = "~4"
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app[each.key].id]
  }
  site_config {
    always_on              = true
    vnet_route_all_enabled = true
    minimum_tls_version    = "1.2"
    ftps_state             = "Disabled"
    application_stack { python_version = "3.12" }
  }
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME                  = "python"
    WEBSITE_RUN_FROM_PACKAGE                  = "1"
    AzureWebJobsStorage__accountName          = azurerm_storage_account.host.name
    AzureWebJobsStorage__credential           = "managedidentity"
    AzureWebJobsStorage__clientId             = azurerm_user_assigned_identity.app[each.key].client_id
    AZURE_CLIENT_ID                           = azurerm_user_assigned_identity.app[each.key].client_id
    RotationBus__fullyQualifiedNamespace      = "${azurerm_servicebus_namespace.rotation.name}.servicebus.windows.net"
    RotationBus__credential                   = "managedidentity"
    RotationBus__clientId                     = azurerm_user_assigned_identity.app[each.key].client_id
    BUS_NAMESPACE                             = "${azurerm_servicebus_namespace.rotation.name}.servicebus.windows.net"
    WORK_QUEUE                                = "rotation-work"
    EVENT_QUEUE                               = "vault-events"
    STATE_BLOB_URL                            = azurerm_storage_account.state.primary_blob_endpoint
    ROTATION_ENVIRONMENT                      = var.environment
    ASSETS_JSON                               = jsonencode(var.assets)
    APPROVALS_JSON                            = jsonencode(var.manual_approvals)
    CONSUMER_HOSTS_JSON                       = jsonencode(var.consumer_hosts)
    TENANT_ID                                 = var.tenant_id
    APPLICATIONINSIGHTS_CONNECTION_STRING     = azurerm_application_insights.rotation.connection_string
    APPLICATIONINSIGHTS_AUTHENTICATION_STRING = "ClientId=${azurerm_user_assigned_identity.app[each.key].client_id};Authorization=AAD"
    "AzureWebJobs.reconcile.Disabled"         = each.key == "scheduler" ? "false" : "true"
    "AzureWebJobs.rotate.Disabled"            = each.key == "worker" ? "false" : "true"
    "AzureWebJobs.lifecycle_event.Disabled"   = each.key == "worker" && var.event_delivery_exception_approved ? "false" : "true"
    "AzureWebJobs.request_rotation.Disabled"  = each.key == "worker" ? "false" : "true"
  }
  auth_settings_v2 {
    auth_enabled           = true
    require_authentication = true
    unauthenticated_action = "Return401"
    default_provider       = "azureactivedirectory"
    active_directory_v2 {
      client_id            = var.manual_api_client_id
      tenant_auth_endpoint = "https://login.microsoftonline.com/${var.tenant_id}/v2.0"
      allowed_audiences    = ["api://${var.manual_api_client_id}"]
      jwt_allowed_groups   = var.operator_group_ids
    }
    login { token_store_enabled = false }
  }
  tags = var.tags
  depends_on = [terraform_data.contract, azurerm_role_assignment.host_blob, azurerm_role_assignment.host_queue,
  azurerm_role_assignment.metadata, azurerm_role_assignment.sender, azurerm_role_assignment.receiver]
}
resource "azurerm_private_endpoint" "rotation" {
  for_each            = local.endpoints
  name                = "${var.names.worker}-${each.key}-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.rotation.name
  subnet_id           = var.private_endpoint_subnet_id
  private_service_connection {
    name                           = "${each.key}-connection"
    private_connection_resource_id = each.value.id
    subresource_names              = [each.value.group]
    is_manual_connection           = false
  }
  dynamic "private_dns_zone_group" {
    for_each = var.dns_owned_by_policy ? [] : [1]
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_ids[each.value.dns]]
    }
  }
  tags = var.tags
}
resource "terraform_data" "code" {
  for_each         = var.package_path == null ? {} : local.apps
  triggers_replace = [filesha256(var.package_path), azurerm_linux_function_app.app[each.key].id]
  lifecycle {
    replace_triggered_by = [azurerm_linux_function_app.app[each.key]]
  }
  provisioner "local-exec" {
    # CLI uses the runner's federated identity. Kudu basic publishing stays off.
    command = "bash \"${path.module}/runtime/deploy.sh\""
    environment = {
      ROTATION_RG           = azurerm_resource_group.rotation.name
      ROTATION_APP          = each.value
      ROTATION_ZIP          = abspath(var.package_path)
      ROTATION_SUBSCRIPTION = split("/", azurerm_linux_function_app.app[each.key].id)[2]
    }
  }
  depends_on = [azurerm_private_endpoint.rotation, azurerm_role_assignment.vault,
  azurerm_role_assignment.vault_metadata, azurerm_role_assignment.storage_keys, azurerm_role_assignment.telemetry]
}
resource "azurerm_monitor_diagnostic_setting" "bus" {
  name                       = "rotation-central"
  target_resource_id         = azurerm_servicebus_namespace.rotation.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  enabled_log { category_group = "allLogs" }
  enabled_metric { category = "AllMetrics" }
}
resource "azurerm_monitor_metric_alert" "deadletters" {
  name                = "${var.names.worker}-deadletters"
  resource_group_name = azurerm_resource_group.rotation.name
  scopes              = [azurerm_servicebus_namespace.rotation.id]
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT5M"
  criteria {
    metric_namespace = "Microsoft.ServiceBus/namespaces"
    metric_name      = "DeadletteredMessages"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 0
  }
  dynamic "action" {
    for_each = var.action_group_ids
    content { action_group_id = action.value }
  }
}
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "rotation" {
  for_each = {
    failure   = "where Message startswith 'ROTATION ' | where Message has_any ('ManualIntervention', 'GovernanceBlocked', 'SchedulerFailure', 'Overdue')"
    heartbeat = "where Message startswith 'ROTATION ' and Message has 'Heartbeat' | summarize Last=max(TimeGenerated) | where isnull(Last) or Last < ago(15m)"
  }
  name                 = "${var.names.worker}-${each.key}"
  resource_group_name  = azurerm_resource_group.rotation.name
  location             = var.location
  scopes               = [var.log_analytics_workspace_id]
  severity             = 1
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  criteria {
    query                   = "AppTraces | where _ResourceId =~ '${azurerm_application_insights.rotation.id}' | ${each.value}"
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }
  action { action_groups = var.action_group_ids }
}
resource "azurerm_monitor_metric_alert" "backlog" {
  for_each            = azurerm_servicebus_queue.rotation
  name                = "${var.names.worker}-${each.key}-backlog"
  resource_group_name = azurerm_resource_group.rotation.name
  scopes              = [azurerm_servicebus_namespace.rotation.id]
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"
  criteria {
    metric_namespace = "Microsoft.ServiceBus/namespaces"
    metric_name      = "ActiveMessages"
    aggregation      = "Minimum"
    operator         = "GreaterThan"
    threshold        = 0
    dimension {
      name     = "EntityName"
      operator = "Include"
      values   = [each.key]
    }
  }
  dynamic "action" {
    for_each = var.action_group_ids
    content { action_group_id = action.value }
  }
}
