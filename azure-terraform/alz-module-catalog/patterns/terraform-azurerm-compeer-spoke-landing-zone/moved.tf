# Preserve addresses for retained vault and approved telemetry deployments.
moved {
  from = module.key_vault
  to   = module.key_vault[0]
}

moved {
  from = module.application_insights
  to   = module.application_insights[0]
}

moved {
  from = module.failed_requests_alert
  to   = module.failed_requests_alert[0]
}
