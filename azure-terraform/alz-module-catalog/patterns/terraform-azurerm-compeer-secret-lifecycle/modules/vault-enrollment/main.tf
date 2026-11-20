terraform {
  required_version = ">= 1.11.4, < 2.0.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">= 4.81.0, < 5.0.0" }
  }
}
variable "vault_id" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "topic_name" { type = string }
variable "secret_names" { type = set(string) }
variable "events_enabled" {
  type    = bool
  default = false
}
variable "delivery_exception_approved" {
  type    = bool
  default = false
}
variable "queue_id" { type = string }
variable "dead_letter_storage_id" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
resource "terraform_data" "contract" {
  lifecycle {
    precondition {
      condition     = !var.events_enabled || (var.delivery_exception_approved && length(var.secret_names) > 0)
      error_message = "Event delivery requires network exception approval and an explicit secret allowlist."
    }
  }
}
resource "azurerm_eventgrid_system_topic" "vault" {
  count               = var.events_enabled ? 1 : 0
  name                = var.topic_name
  resource_group_name = var.resource_group_name
  location            = var.location
  source_resource_id  = var.vault_id
  topic_type          = "Microsoft.KeyVault.vaults"
  identity { type = "SystemAssigned" }
  tags       = var.tags
  depends_on = [terraform_data.contract]
}
resource "azurerm_role_assignment" "sender" {
  count                = var.events_enabled ? 1 : 0
  scope                = var.queue_id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_eventgrid_system_topic.vault[0].identity[0].principal_id
}
resource "azurerm_role_assignment" "deadletter" {
  count                = var.events_enabled ? 1 : 0
  scope                = "${var.dead_letter_storage_id}/blobServices/default/containers/event-deadletters"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_eventgrid_system_topic.vault[0].identity[0].principal_id
}
resource "azurerm_eventgrid_system_topic_event_subscription" "vault" {
  count                         = var.events_enabled ? 1 : 0
  name                          = "secret-lifecycle"
  system_topic                  = azurerm_eventgrid_system_topic.vault[0].name
  resource_group_name           = var.resource_group_name
  service_bus_queue_endpoint_id = var.queue_id
  included_event_types          = ["Microsoft.KeyVault.SecretNearExpiry"]
  event_delivery_schema         = "EventGridSchema"
  delivery_identity { type = "SystemAssigned" }
  dead_letter_identity { type = "SystemAssigned" }
  storage_blob_dead_letter_destination {
    storage_account_id          = var.dead_letter_storage_id
    storage_blob_container_name = "event-deadletters"
  }
  advanced_filter {
    string_in {
      key    = "data.ObjectName"
      values = sort(tolist(var.secret_names))
    }
  }
  retry_policy {
    event_time_to_live    = 1440
    max_delivery_attempts = 30
  }
  depends_on = [azurerm_role_assignment.sender, azurerm_role_assignment.deadletter]
}
resource "azurerm_monitor_diagnostic_setting" "vault" {
  name                       = "rotation-central"
  target_resource_id         = var.vault_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  enabled_log { category_group = "audit" }
  enabled_metric { category = "AllMetrics" }
}
output "topic_id" { value = try(azurerm_eventgrid_system_topic.vault[0].id, null) }
