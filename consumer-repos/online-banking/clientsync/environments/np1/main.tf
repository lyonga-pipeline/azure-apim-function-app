data "azurerm_client_config" "current" {}

data "tfe_outputs" "platform_management" {
  count        = try(var.platform_outputs.enabled, false) ? 1 : 0
  organization = var.platform_outputs.hcp_organization
  workspace    = var.platform_outputs.platform_management_workspace
}

data "tfe_outputs" "platform_connectivity" {
  count        = try(var.platform_outputs.enabled, false) ? 1 : 0
  organization = var.platform_outputs.hcp_organization
  workspace    = var.platform_outputs.platform_connectivity_workspace
}

data "tfe_outputs" "workload_spoke" {
  count        = try(var.platform_outputs.enabled, false) ? 1 : 0
  organization = var.platform_outputs.hcp_organization
  workspace    = var.platform_outputs.workload_spoke_workspace
}

resource "terraform_data" "platform_output_contract" {
  count = local.platform_outputs_enabled ? 1 : 0
  input = local.platform_output_errors

  lifecycle {
    precondition {
      condition     = length(local.platform_output_errors) == 0
      error_message = join("\n", local.platform_output_errors)
    }
  }
}

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
  network              = local.network
  private_endpoints    = local.private_endpoints
  diagnostics          = local.diagnostics
  role_assignments     = var.role_assignments
  alerts               = local.alerts

  depends_on = [terraform_data.platform_output_contract]
}
