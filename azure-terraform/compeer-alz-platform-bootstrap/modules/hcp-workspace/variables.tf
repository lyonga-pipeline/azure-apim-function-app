variable "organization" { type = string }
variable "project_id" { type = string }
variable "name" { type = string }
variable "description" { type = string }
variable "working_directory" { type = string }
variable "vcs_identifier" { type = string }
variable "branch" {
  type    = string
  default = "main"
}
variable "oauth_token_id" { type = string }
variable "execution_mode" {
  type    = string
  default = "agent"
  validation {
    condition     = contains(["agent", "remote"], var.execution_mode)
    error_message = "execution_mode must be agent or remote."
  }
}
variable "agent_pool_id" {
  type    = string
  default = null
}
variable "auto_apply" {
  type    = bool
  default = false
}
variable "speculative_enabled" {
  type    = bool
  default = true
}
variable "file_triggers_enabled" {
  type    = bool
  default = true
}
variable "trigger_patterns" {
  type    = list(string)
  default = []
}
variable "terraform_version" {
  description = "Exact Terraform version configured on the HCP workspace, e.g. 1.9.5."
  type        = string
}
variable "assessments_enabled" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
