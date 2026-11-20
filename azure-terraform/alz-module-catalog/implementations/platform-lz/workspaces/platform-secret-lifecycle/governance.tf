variable "governance_policies" {
  description = "Existing approved built-in Key Vault policy definitions; Audit first. Central remediation policies remain centrally owned."
  type        = map(object({ name = string, definition_id = string, parameters = string, enforce = optional(bool, false) }))
  default     = {}
}
module "governance" {
  source          = "../../../../patterns/terraform-azurerm-compeer-secret-lifecycle/modules/governance"
  subscription_id = "/subscriptions/${var.subscription_id}"
  policies        = var.governance_policies
}
