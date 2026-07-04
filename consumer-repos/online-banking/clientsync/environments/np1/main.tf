data "azurerm_client_config" "current" {}

module "clientsync_function_app" {
  source = "../../../../../azure-terraform/patterns/function-app"

  environment = var.environment
  location    = var.location
  tenant_id   = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)

  application          = var.application
  resource_group       = var.resource_group
  identity             = var.identity
  app_service_plan     = local.app_service_plan
  storage_account      = local.storage_account
  key_vault            = local.key_vault
  application_insights = var.application_insights
  function_app         = local.function_app
  network              = var.network
  private_endpoints    = var.private_endpoints
  diagnostics          = var.diagnostics
  role_assignments     = var.role_assignments
  alerts               = var.alerts
}
