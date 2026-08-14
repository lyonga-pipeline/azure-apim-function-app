output "ids" {
  description = "Flow log IDs keyed by input key."
  value       = { for key, flow_log in azurerm_network_watcher_flow_log.this : key => flow_log.id }
}
