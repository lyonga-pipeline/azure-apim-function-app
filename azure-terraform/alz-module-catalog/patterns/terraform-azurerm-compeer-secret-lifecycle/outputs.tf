output "worker_identity" {
  value = { id = azurerm_user_assigned_identity.app["worker"].id,
    client_id = azurerm_user_assigned_identity.app["worker"].client_id,
  principal_id = azurerm_user_assigned_identity.app["worker"].principal_id }
}
output "enrollment" {
  description = "Pass to workload-owned vault enrollment modules. Queue and dead-letter destination contain no secrets."
  value = {
    queue_id                   = azurerm_servicebus_queue.rotation["vault-events"].id
    dead_letter_storage_id     = azurerm_storage_account.state.id
    dead_letter_container_name = azurerm_storage_container.state["event-deadletters"].name
    event_delivery_approved    = var.event_delivery_exception_approved
    environment                = var.environment
  }
}
output "manual_request_url" { value = "https://${azurerm_linux_function_app.app["worker"].default_hostname}/api/rotation/request" }
output "function_app_ids" { value = { for key, app in azurerm_linux_function_app.app : key => app.id } }
