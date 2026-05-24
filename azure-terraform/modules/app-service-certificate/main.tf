resource "azurerm_app_service_certificate" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  app_service_plan_id = var.app_service_plan_id
  key_vault_id        = var.key_vault_id
  key_vault_secret_id = var.key_vault_secret_id
  pfx_blob            = var.pfx_blob
  password            = var.password
  tags                = var.tags

  lifecycle {
    precondition {
      condition = (
        (var.key_vault_secret_id != null) != (var.pfx_blob != null)
      )
      error_message = "Set exactly one of key_vault_secret_id or pfx_blob."
    }
    precondition {
      condition     = var.pfx_blob == null || var.password != null
      error_message = "password is required when pfx_blob is set."
    }
  }
}
