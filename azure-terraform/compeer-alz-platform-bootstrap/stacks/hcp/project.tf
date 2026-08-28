resource "tfe_project" "alz" {
  organization = var.organization_name
  name         = var.project.name
  description  = var.project.description
  tags         = var.project.tags

  lifecycle {
    prevent_destroy = true
  }
}
