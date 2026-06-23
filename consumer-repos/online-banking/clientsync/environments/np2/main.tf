module "clientsync_function_app" {
  source = "../../../../../azure-terraform/patterns/function-app"

  environment = var.environment
  location    = var.location
  tenant_id   = var.tenant_id

  application          = var.application
  resource_group       = var.resource_group
  identity             = var.identity
  app_service_plan     = var.app_service_plan
  storage_account      = var.storage_account
  key_vault            = local.key_vault
  application_insights = var.application_insights
  function_app         = local.function_app
  network              = var.network
  private_endpoints    = var.private_endpoints
  diagnostics          = var.diagnostics
  role_assignments     = var.role_assignments
  alerts               = var.alerts
}
