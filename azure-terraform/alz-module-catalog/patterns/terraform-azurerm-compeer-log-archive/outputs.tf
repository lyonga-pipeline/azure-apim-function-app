output "storage_account_ids" { value = { for key, account in module.storage : key => account.id } }
output "export_ids" { value = { for key, rule in azurerm_log_analytics_data_export_rule.archive : key => rule.id } }
