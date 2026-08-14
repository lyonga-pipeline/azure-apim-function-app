output "defender_plan_ids" {
  description = "Defender plan IDs keyed by input key."
  value       = { for key, plan in azurerm_security_center_subscription_pricing.this : key => plan.id }
}

output "posture_contract" {
  description = "No-cost SOC target-state contract."
  value       = terraform_data.posture_contract.output
}
