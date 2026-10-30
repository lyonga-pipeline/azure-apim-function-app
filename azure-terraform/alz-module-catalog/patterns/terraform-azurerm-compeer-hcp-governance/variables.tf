variable "organization" {
  description = "Existing HCP organization. Credentials are supplied outside Terraform variables."
  type        = string
}
# PHASE2 NEW: IAC-06. Read current settings before adoption; import and confirm the agent pool.
variable "workspace_settings" {
  type = map(object({
    workspace_id              = string
    workspace_name            = string
    execution_mode            = string
    agent_pool_id             = optional(string)
    assessments_enabled       = optional(bool, true)
    remote_state_consumer_ids = optional(set(string))
    ownership_approved        = bool
  }))
  default = {}
  validation {
    condition = alltrue([for workspace in values(var.workspace_settings) :
      workspace.ownership_approved && contains(["remote", "agent"], workspace.execution_mode) &&
      (workspace.execution_mode == "agent" ? workspace.agent_pool_id != null : workspace.agent_pool_id == null) &&
      can(regex("^ws-[a-zA-Z0-9]{16}$", workspace.workspace_id)) && length(trimspace(workspace.workspace_name)) > 0
    ])
    error_message = "Use the actual workspace name/ID and preserve its remote/agent execution context with explicit ownership approval."
  }
}
