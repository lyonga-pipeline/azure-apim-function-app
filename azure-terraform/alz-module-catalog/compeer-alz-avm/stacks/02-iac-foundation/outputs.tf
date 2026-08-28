output "project_ids" {
  value = { for key, project in tfe_project.this : key => project.id }
}

output "workspace_ids" {
  value = { for key, workspace in tfe_workspace.this : key => workspace.id }
}

output "team_ids" {
  value = { for key, team in tfe_team.this : key => team.id }
}

output "variable_set_ids" {
  value = { for key, variable_set in tfe_variable_set.this : key => variable_set.id }
}

output "registry_module_ids" {
  value = { for key, registry_module in tfe_registry_module.this : key => registry_module.id }
}

output "policy_set_ids" {
  value = { for key, policy_set in tfe_policy_set.this : key => policy_set.id }
}

output "run_trigger_ids" {
  value = { for key, run_trigger in tfe_run_trigger.this : key => run_trigger.id }
}

output "operational_contracts" {
  value = module.operational_contracts.contracts
}
