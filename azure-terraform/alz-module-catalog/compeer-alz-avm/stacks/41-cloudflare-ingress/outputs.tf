output "zone_ids" {
  value = { for key, zone in module.zone : key => zone.zone_id }
}

output "record_ids" {
  value = { for key, record in module.record : key => record.record_resource_id }
}

output "record_hostnames" {
  value = { for key, record in module.record : key => record.record_hostname }
}

output "ruleset_ids" {
  value = { for key, ruleset in module.ruleset : key => ruleset.id }
}

output "operational_contracts" {
  value = module.operational_contracts.contracts
}
