resource "tfe_variable_set" "alz" {
  for_each = var.variable_sets

  name         = each.value.name
  description  = each.value.description
  organization = var.organization_name
  priority     = each.value.priority
}

resource "tfe_project_variable_set" "alz" {
  for_each = var.variable_sets

  project_id      = tfe_project.alz.id
  variable_set_id = tfe_variable_set.alz[each.key].id
}

resource "tfe_project_variable_set" "existing" {
  for_each = var.existing_project_variable_sets

  project_id      = tfe_project.alz.id
  variable_set_id = data.tfe_variable_set.existing_project[each.key].id
}

resource "tfe_variable" "variable_set" {
  for_each = local.variable_set_variables

  variable_set_id = tfe_variable_set.alz[each.value.variable_set_key].id
  key             = each.value.key
  value           = each.value.value
  category        = each.value.category
  description     = each.value.description
  sensitive       = each.value.sensitive
  hcl             = each.value.hcl
}
