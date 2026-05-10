output "resource_group_name" {
  value = module.resource_group.name
}

output "application_gateway_public_ip" {
  value = module.gateway_public_ip.ip_address
}

output "apim_gateway_url" {
  value = module.apim_service.gateway_url
}

output "synapse_workspace_id" {
  value = module.synapse_workspace.id
}
