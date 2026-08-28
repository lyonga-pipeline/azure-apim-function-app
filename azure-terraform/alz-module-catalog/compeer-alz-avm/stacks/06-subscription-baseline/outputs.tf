output "resource_group_ids" { value = { for key, rg in module.resource_groups : key => rg.id } }
output "role_assignment_ids" { value = module.role_assignments.ids }
output "subscription_activity_log_id" { value = try(module.subscription_activity_log[0].id, null) }
output "policy_assignment_ids" { value = module.policy_baseline.subscription_assignment_ids }
output "defender_plan_ids" { value = module.defender_soc_posture.defender_plan_ids }
output "budget_ids" { value = { for key, budget in azurerm_consumption_budget_subscription.budget : key => budget.id } }
output "operational_contracts" { value = module.operational_contracts.contracts }
