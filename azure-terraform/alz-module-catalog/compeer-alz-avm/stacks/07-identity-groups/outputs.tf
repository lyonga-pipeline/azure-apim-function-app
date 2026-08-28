output "group_object_ids" { value = { for key, group in module.rbac_groups : key => group.object_id } }
output "operational_contracts" { value = module.operational_contracts.contracts }
