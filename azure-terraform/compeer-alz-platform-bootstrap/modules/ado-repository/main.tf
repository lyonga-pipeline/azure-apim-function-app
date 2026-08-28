resource "azuredevops_git_repository" "this" {
  project_id     = var.project_id
  name           = var.name
  default_branch = var.default_branch

  initialization {
    init_type = "Clean"
  }

  lifecycle {
    # Provider guidance: initialization is a create/import concern and should not
    # continuously drive repository replacement after creation.
    ignore_changes  = [initialization]
    prevent_destroy = true
  }
}

resource "azuredevops_git_repository_file" "managed" {
  for_each = var.files

  repository_id       = azuredevops_git_repository.this.id
  file                = each.key
  content             = each.value
  branch              = var.default_branch
  commit_message      = "chore: seed ALZ repository baseline"
  overwrite_on_create = true
}

resource "azuredevops_build_definition" "validation" {
  count = var.create_pipeline ? 1 : 0

  project_id = var.project_id
  name       = var.pipeline_name
  path       = var.pipeline_folder

  ci_trigger {
    use_yaml = true
  }

  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.this.id
    branch_name = var.default_branch
    yml_path    = var.pipeline_yml_path
  }

  depends_on = [azuredevops_git_repository_file.managed]
}
