output "action_group_ids" {
  value = { for key, action_group in module.action_group : key => action_group.id }
}

output "metric_alert_ids" {
  value = { for key, alert in module.metric_alert : key => alert.id }
}

output "operational_contracts" {
  value = module.operational_contracts.contracts
}
