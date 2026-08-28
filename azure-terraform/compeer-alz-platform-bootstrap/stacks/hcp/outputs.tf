output "project" {
  value = {
    id   = tfe_project.alz.id
    name = tfe_project.alz.name
  }
}

output "workspaces" {
  value = {
    for key, ws in module.workspaces : key => {
      id   = ws.id
      name = ws.name
    }
  }
}

output "variable_sets" {
  value = {
    for key, vs in tfe_variable_set.alz : key => {
      id   = vs.id
      name = vs.name
    }
  }
}

output "opa_policy_set_id" {
  value = try(tfe_policy_set.opa[0].id, null)
}
