output "audit_assignment_ids" { value = { for key, value in azurerm_management_group_policy_assignment.audit : key => value.id } }
output "budget_ids" { value = { for key, value in azurerm_consumption_budget_subscription.subscription : key => value.id } }
output "cost_export_ids" { value = { for key, value in azurerm_subscription_cost_management_export.cost : key => value.id } }
output "exemption_ids" { value = merge(module.exemptions.policy_exemption_ids, { for key, value in azurerm_resource_policy_exemption.resource : key => value.id }) }
