output "ids" {
  description = "Flow log IDs keyed by input key."
  value       = { for key, flow_log in azurerm_network_watcher_flow_log.this : key => flow_log.id }
}

output "names" {
  description = "Flow log names keyed by input key."
  value       = { for key, flow_log in azurerm_network_watcher_flow_log.this : key => flow_log.name }
}

output "flow_logs" {
  description = "Network Watcher flow log attributes keyed by input key for downstream composition."
  value = {
    for key, flow_log in azurerm_network_watcher_flow_log.this : key => {
      id                        = flow_log.id
      name                      = flow_log.name
      resource_group_name       = flow_log.resource_group_name
      network_watcher_name      = flow_log.network_watcher_name
      network_security_group_id = flow_log.network_security_group_id
      storage_account_id        = flow_log.storage_account_id
      enabled                   = flow_log.enabled
    }
  }
}
