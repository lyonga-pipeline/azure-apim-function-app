output "log_alert_ids" { value = { for key, value in azurerm_monitor_scheduled_query_rules_alert_v2.platform : key => value.id } }
output "agent_ids" { value = { for key, value in azurerm_virtual_machine_extension.ama : key => value.id } }
output "workbook_ids" { value = { for key, value in azurerm_application_insights_workbook.operations : key => value.id } }
output "connection_monitor_ids" { value = { for key, value in azurerm_network_connection_monitor.path : key => value.id } }
output "association_ids" { value = { for key, value in azurerm_monitor_data_collection_rule_association.vm : key => value.id } }
output "endpoint_association_ids" { value = { for key, value in azurerm_monitor_data_collection_rule_association.endpoint : key => value.id } }
output "metric_alert_ids" { value = { for key, value in module.metric_alerts : key => value.id } }
