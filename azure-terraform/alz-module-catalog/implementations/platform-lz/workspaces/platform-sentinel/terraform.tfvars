# Sentinel content workspace (deployed AFTER platform-management).
#
# Ships disabled: Security Operations owns detection priorities and connector
# approvals, and platform-management currently owns the Sentinel onboarding and
# the Defender for Cloud connector. Set enabled = true only after the handover
# in patterns/terraform-azurerm-compeer-sentinel-content/README.md ("Adopting
# connectors and rules from platform-management").
#
# tenant_id / subscription_id (the MANAGEMENT subscription) and any TAXII
# passwords come from HCP variables, never from this file.
tfe_organization          = "REPLACE_HCP_ORGANIZATION"
management_workspace_name = "platform-management"

sentinel = {
  enabled = false

  # One owner per connector: leave a connector off here while
  # platform-management's sentinel.data_connectors still enables it.
  data_connectors = {}

  # Feeds delivered by OTHER states. Declare a feed only once its owner has it
  # flowing; rules that read it are blocked at plan time until then.
  #   azure_activity       <- platform-management subscription_activity_log_diagnostics
  #   entra_audit_logs /
  #   entra_signin_logs    <- platform-management entra_diagnostic_settings
  #   common_security_log  <- Palo Alto CEF forwarder + data collection rule
  externally_provided_sources = []

  # SOC-owned data sources (agent feeds and third-party pipelines such as
  # Cribl delivering Cloudflare logs): data collection endpoints, custom
  # tables, rules and associations. Leave null while platform-management owns
  # the same rules; see the pattern README for the Cribl example.
  ingestion = null

  baseline_content = { enabled = false }

  # Example, once the SOC approves it:
  # microsoft_incident_rules = {
  #   defender-for-cloud-high-medium = {
  #     display_name    = "Defender for Cloud - High and Medium"
  #     product_filter  = "Azure Security Center"
  #     severity_filter = ["High", "Medium"]
  #   }
  # }
}
