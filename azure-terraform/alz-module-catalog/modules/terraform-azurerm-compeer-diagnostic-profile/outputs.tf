output "log_categories" {
  description = "Default log category_group(s), as a list for direct use in a diagnostic_settings.logs-shaped map."
  value       = [var.log_category_group]
}

output "metric_categories" {
  description = "Default metric categories, as a list."
  value       = [var.metric_category]
}

output "destination_key" {
  value = var.destination_key
}

output "profile" {
  description = "Platform_Output_Contracts_IAC-10 management_diagnostic_profile - the combined object(log_categories, metric_categories, destination_key)."
  value = {
    log_categories    = [var.log_category_group]
    metric_categories = [var.metric_category]
    destination_key   = var.destination_key
  }
}
