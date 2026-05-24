resource "azurerm_app_service_managed_certificate" "this" {
  custom_hostname_binding_id = var.custom_hostname_binding_id
  tags                       = var.tags
}
