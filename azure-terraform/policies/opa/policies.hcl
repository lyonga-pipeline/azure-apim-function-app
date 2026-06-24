policy "net-new-landing-zone-guardrails" {
  query             = "data.compeer.lz.deny"
  enforcement_level = "advisory"
  description       = "Plan-time guardrails for Compeer net-new landing-zone HCP workspaces."
}
