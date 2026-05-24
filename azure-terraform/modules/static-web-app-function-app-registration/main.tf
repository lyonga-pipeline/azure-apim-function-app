resource "azurerm_static_web_app_function_app_registration" "this" {
  static_web_app_id = var.static_web_app_id
  function_app_id   = var.function_app_id
}
