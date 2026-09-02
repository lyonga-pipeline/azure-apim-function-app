variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by the governance deployment identity."
  type        = string
}

variable "execution_subscription_id" {
  description = "Subscription used by the provider for governance operations."
  type        = string
}

variable "location" {
  description = "Default Azure region for policy assignments that need a managed identity."
  type        = string
  default     = "centralus"
}

variable "governance" {
  description = "Governance workspace configuration: management groups, policy, custom roles, RBAC, and MG budgets."
  type        = any
  default = {
    enabled           = false
    management_groups = {}
  }
}

variable "environment" {
  description = "Environment token, required by the naming module (MG names take the env from their key, not this)."
  type        = string
  default     = "prod"
}
