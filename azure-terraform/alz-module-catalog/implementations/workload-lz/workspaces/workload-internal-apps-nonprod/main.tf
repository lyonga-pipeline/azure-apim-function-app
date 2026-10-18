module "deployment" {
  source = "../../shared"
  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
    azurerm.dns          = azurerm.dns
    tfe                  = tfe
    time                 = time
  }
  subscription_id             = var.subscription_id
  tenant_id                   = var.tenant_id
  environment                 = var.environment
  configuration               = var.spoke
  use_tfe_outputs             = var.use_tfe_outputs
  tfe_organization            = var.tfe_organization
  management_workspace_name   = var.management_workspace_name
  connectivity_workspace_name = var.connectivity_workspace_name
  governance_workspace_name   = var.governance_workspace_name
  platform_inputs             = var.platform_inputs
}
