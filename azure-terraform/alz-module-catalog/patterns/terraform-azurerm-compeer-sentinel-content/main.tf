# Onboarding is opt-in. platform-management normally owns it; two states must
# never own the same onboarding. Everything below is addressed through
# local.workspace_id so that, when this state does onboard, rules and
# connectors are ordered after the onboarding without a depends_on.
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "onboarding" {
  count = var.manage_onboarding ? 1 : 0

  workspace_id = var.log_analytics_workspace_id
}

locals {
  workspace_id = try(azurerm_sentinel_log_analytics_workspace_onboarding.onboarding[0].workspace_id, var.log_analytics_workspace_id)

  connectors = var.data_connectors

  # Which telemetry sources an enabled connector in THIS state delivers. A
  # logical source is available when any one of its connectors is on.
  connector_sources = {
    security_alert = anytrue([
      local.connectors.entra_id,
      local.connectors.defender_xdr,
      local.connectors.defender_for_endpoint,
      local.connectors.defender_for_identity,
      local.connectors.defender_for_cloud_apps != null,
      local.connectors.office_atp,
      length(local.connectors.defender_for_cloud) > 0,
    ])
    threat_intelligence_indicator = anytrue([
      local.connectors.threat_intelligence != null,
      local.connectors.microsoft_threat_intelligence != null,
      length(local.connectors.threat_intelligence_taxii) > 0,
    ])
    office_activity = anytrue([
      local.connectors.office_365 != null,
      local.connectors.office_irm,
      local.connectors.power_bi,
    ])
  }

  available_sources = toset(concat(
    var.externally_provided_sources,
    [for source, provided in local.connector_sources : source if provided],
    local.ingestion_sources,
  ))
}

# Plan-time guard: a rule whose source table does not exist yet is the most
# common first-deployment failure for Sentinel content. Each rule declares the
# feeds it reads; the plan stops with the exact rule/source pairs that are not
# covered. Disable with enforce_source_dependencies = false only for a staged
# rollout where the feed is known to be arriving.
resource "terraform_data" "source_dependency_contract" {
  input = {
    available_sources = sort(tolist(local.available_sources))
    unmet             = local.unmet_sources
  }

  lifecycle {
    precondition {
      condition     = !var.enforce_source_dependencies || length(local.unmet_sources) == 0
      error_message = "Enabled Sentinel rules need telemetry that nothing provides yet: ${jsonencode(local.unmet_sources)}. Enable the matching connector here, list the feed in externally_provided_sources once its owner has it flowing (Activity Log / Entra diagnostic settings, CEF forwarder), or disable the rule."
    }
  }
}
