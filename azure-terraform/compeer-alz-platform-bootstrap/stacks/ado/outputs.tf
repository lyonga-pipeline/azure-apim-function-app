output "repositories" {
  value = {
    for key, repo in module.repositories : key => {
      id             = repo.repository_id
      name           = repo.repository_name
      default_branch = repo.default_branch
      pipeline_id    = repo.pipeline_id
    }
  }
}
