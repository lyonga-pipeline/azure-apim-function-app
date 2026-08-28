locals {
  agent_pool_names = toset([
    for ws in values(var.workspaces) : ws.agent_pool_name
    if ws.execution_mode == "agent" && ws.agent_pool_name != null
  ])

  variable_set_variables = merge({}, [
    for set_key, set_config in var.variable_sets : {
      for variable_key, variable in set_config.variables : "${set_key}:${variable_key}" => merge(variable, {
        variable_set_key = set_key
        key              = variable_key
      })
    }
  ]...)

  workspace_tf_variables = merge({}, [
    for workspace_key, workspace in var.workspaces : {
      for variable_key, variable in workspace.terraform_variables : "${workspace_key}:tf:${variable_key}" => merge(variable, {
        workspace_key = workspace_key
        key           = variable_key
      })
    }
  ]...)

  workspace_env_variables = merge({}, [
    for workspace_key, workspace in var.workspaces : {
      for variable_key, variable in workspace.environment_variables : "${workspace_key}:env:${variable_key}" => merge(variable, {
        workspace_key = workspace_key
        key           = variable_key
      })
    }
  ]...)

  workspace_variable_set_links = merge({}, [
    for workspace_key, workspace in var.workspaces : {
      for set_key in workspace.variable_sets : "${workspace_key}:${set_key}" => {
        workspace_key    = workspace_key
        variable_set_key = set_key
      }
    }
  ]...)
}
