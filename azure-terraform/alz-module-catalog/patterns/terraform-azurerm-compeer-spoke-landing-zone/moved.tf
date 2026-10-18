moved {
  from = module.hub_to_spoke[0]
  to   = module.peering[0].module.hub_to_spoke_peering
}

moved {
  from = module.spoke_to_hub[0]
  to   = module.peering[0].module.spoke_to_hub_peering
}

# Preserve addresses if an existing, approved telemetry/budget deployment remains enabled.
moved {
  from = module.application_insights
  to   = module.application_insights[0]
}

moved {
  from = module.failed_requests_alert
  to   = module.failed_requests_alert[0]
}

moved {
  from = module.budget
  to   = module.budget[0]
}
