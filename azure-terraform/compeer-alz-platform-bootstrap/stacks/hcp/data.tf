data "tfe_oauth_client" "ado" {
  organization     = var.organization_name
  service_provider = "ado_services"
  name             = var.oauth_client_name
}

data "tfe_agent_pool" "existing" {
  for_each = local.agent_pool_names

  organization = var.organization_name
  name         = each.value
}

data "tfe_variable_set" "existing_project" {
  for_each = var.existing_project_variable_sets

  organization = var.organization_name
  name         = each.value
}
