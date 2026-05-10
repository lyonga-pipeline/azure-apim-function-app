output "resource_group_name" {
  value = module.resource_group.name
}

output "function_app_default_hostname" {
  value = module.function_app.default_hostname
}

output "eventgrid_topic_endpoint" {
  value = module.eventgrid_topic.endpoint
}

output "container_group_fqdn" {
  value = module.container_group.fqdn
}
