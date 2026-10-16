output "content_inventory" {
  description = "What this workspace owns in Sentinel, by kind."
  value       = try(module.sentinel_content[0].content_inventory, null)
}

output "source_coverage" {
  description = "Telemetry sources available to rules and any unmet rule requirements."
  value       = try(module.sentinel_content[0].source_coverage, null)
}

output "connector_ids" {
  description = "Terraform-owned data connector IDs."
  value       = try(module.sentinel_content[0].connector_ids, {})
}

output "analytics_rule_ids" {
  description = "Analytics rule IDs keyed by rule key."
  value       = try(module.sentinel_content[0].analytics_rule_ids, {})
}

output "automation_rule_ids" {
  description = "Automation rule IDs keyed by rule key."
  value       = try(module.sentinel_content[0].automation_rule_ids, {})
}

output "watchlist_ids" {
  description = "Watchlist IDs keyed by alias."
  value       = try(module.sentinel_content[0].watchlist_ids, {})
}
