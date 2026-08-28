output "repository_id" { value = azuredevops_git_repository.this.id }
output "repository_name" { value = azuredevops_git_repository.this.name }
output "default_branch" { value = azuredevops_git_repository.this.default_branch }
output "pipeline_id" { value = try(azuredevops_build_definition.validation[0].id, null) }
