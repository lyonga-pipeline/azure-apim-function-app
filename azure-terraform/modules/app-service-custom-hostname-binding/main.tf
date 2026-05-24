resource "azurerm_app_service_custom_hostname_binding" "this" {
  hostname            = var.hostname
  app_service_name    = var.app_service_name
  resource_group_name = var.resource_group_name
  ssl_state           = var.ssl_state
  thumbprint          = var.thumbprint

  lifecycle {
    precondition {
      condition     = var.ssl_state == null || var.ssl_state == "Disabled" || var.thumbprint != null
      error_message = "thumbprint is required when ssl_state enables TLS."
    }
  }
}
