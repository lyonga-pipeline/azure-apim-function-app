output "settings_ids" {
  description = "Existing workspaces whose health-assessment settings this state owns."
  value       = { for key, value in tfe_workspace_settings.assessments : key => value.id }
}
