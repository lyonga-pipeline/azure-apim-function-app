output "hostpool_id" {
  value = module.avd_management_plane.hostpool_id
}

output "application_group_id" {
  value = module.avd_management_plane.application_group_id
}

output "workspace_id" {
  value = module.avd_management_plane.workspace_id
}

output "scaling_plan_id" {
  value = module.avd_management_plane.scaling_plan_id
}

output "registrationinfo_token" {
  value     = module.avd_management_plane.registrationinfo_token
  sensitive = true
}

output "operational_contracts" {
  value = module.operational_contracts.contracts
}
