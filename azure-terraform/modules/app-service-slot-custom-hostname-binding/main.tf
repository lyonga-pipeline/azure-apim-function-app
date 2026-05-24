resource "azurerm_app_service_slot_custom_hostname_binding" "this" {
  hostname            = var.hostname
  app_service_slot_id = var.app_service_slot_id
  ssl_state           = var.ssl_state
  thumbprint          = var.thumbprint

  lifecycle {
    precondition {
      condition     = var.ssl_state == null || var.ssl_state == "Disabled" || var.thumbprint != null
      error_message = "thumbprint is required when ssl_state enables TLS."
    }
  }
}
