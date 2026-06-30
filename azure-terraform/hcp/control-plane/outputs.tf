output "policy_set_id" {
  description = "HCP Terraform policy set ID."
  value       = tfe_policy_set.opa.id
}

output "policy_set_name" {
  description = "HCP Terraform policy set name."
  value       = tfe_policy_set.opa.name
}

output "policy_set_key" {
  description = "Catalog key used for the policy set."
  value       = var.policy_set_key
}

output "policies_path" {
  description = "Local path uploaded to HCP Terraform as the policy set slug."
  value       = local.opa_policy_directory
}

output "project_scopes" {
  description = "Project scopes attached to the policy set."
  value       = sort(tolist(local.project_scopes))
}

output "workspace_scopes" {
  description = "Workspace scopes attached to the policy set."
  value       = sort(tolist(local.workspace_scopes))
}

output "excluded_workspaces" {
  description = "Workspace exclusions attached to the policy set."
  value       = sort(tolist(local.excluded_workspaces))
}
