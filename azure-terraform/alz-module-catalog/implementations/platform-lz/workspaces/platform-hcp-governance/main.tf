# PHASE2 NEW: health assessments only. No HCP workspaces, teams or repository scaffolding.
module "phase2" {
  source             = "../../../../patterns/terraform-azurerm-compeer-hcp-governance"
  organization       = var.organization
  workspace_settings = var.workspace_settings
}
