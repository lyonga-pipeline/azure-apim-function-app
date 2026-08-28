module "repositories" {
  source   = "../../modules/ado-repository"
  for_each = var.repositories

  project_id        = data.azuredevops_project.existing.id
  name              = each.value.name
  default_branch    = "refs/heads/main"
  files             = local.repository_files[each.key]
  create_pipeline   = each.value.create_pipeline
  pipeline_name     = coalesce(each.value.pipeline_name, "${each.value.name} - Validation")
  pipeline_yml_path = each.value.pipeline_yml_path
  pipeline_folder   = each.value.pipeline_folder
}
