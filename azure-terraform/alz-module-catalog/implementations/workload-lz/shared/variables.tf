variable "subscription_id" {
  description = "Workload subscription UUID supplied through an HCP Terraform-category variable."
  type        = string
  default     = null
}
variable "tenant_id" {
  description = "Tenant UUID from the shared HCP variable set."
  type        = string
  default     = null
}
variable "environment" {
  description = "Environment fixed or constrained by the outer ticket-specific workspace."
  type        = string
}
variable "configuration" {
  description = "Spoke inputs; enabled=false is inert and safe with placeholders. Pattern inputs are strongly typed at the blueprint boundary."
  type        = any
  default     = { enabled = false }
}
variable "use_tfe_outputs" {
  description = "Read only approved public platform outputs; false requires explicit platform_inputs."
  type        = bool
  default     = true
}
variable "tfe_organization" {
  description = "HCP Terraform organization containing platform workspaces."
  type        = string
  default     = null
}
variable "management_workspace_name" {
  description = "Actual HCP workspace name publishing management public outputs."
  type        = string
  default     = "platform-management"
}
variable "connectivity_workspace_name" {
  description = "Actual HCP workspace name publishing connectivity public outputs."
  type        = string
  default     = "platform-connectivity"
}
variable "platform_inputs" {
  description = "Explicit public-contract overrides for isolated deployment/tests; never secrets or full remote state."
  type        = any
  default     = {}
}
