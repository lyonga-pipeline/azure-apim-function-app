output "resource_group_name" {
  value = module.resource_group.name
}

output "log_analytics_workspace_id" {
  value = module.log_analytics.id
}

output "log_analytics_workspace_guid" {
  value = module.log_analytics.workspace_id
}

output "action_group_id" {
  value = module.action_group.id
}

