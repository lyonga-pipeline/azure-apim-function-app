# =============================================================================
# PHASE 2 EXISTING CAPABILITY - SEC-03 / SEC-04
# SOC content stays with this owner; management retains workspace onboarding. Cribl delivery is externally validated.
# Engineering map: implementations/phase2/ENGINEERING-HANDOFF.md
# =============================================================================
data "tfe_outputs" "management" {
  count        = local.enabled && var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.management_workspace_name
}

locals {
  enabled = try(var.sentinel.enabled, false)

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  log_analytics_workspace_id = try(coalesce(var.log_analytics_workspace_id, try(local.management_outputs.log_analytics_workspace_id, null)), null)

  # platform-management publishes sentinel_onboarding_id only when it has
  # onboarded the workspace.
  management_onboarded = try(local.management_outputs.sentinel_onboarding_id, null) != null
  manage_onboarding    = try(var.sentinel.manage_onboarding, false)
}

resource "terraform_data" "platform_contract" {
  count = local.enabled ? 1 : 0

  input = {
    log_analytics_workspace_id = local.log_analytics_workspace_id
    management_onboarded       = local.management_onboarded
    manage_onboarding          = local.manage_onboarding
  }

  lifecycle {
    precondition {
      condition     = local.log_analytics_workspace_id != null
      error_message = "No Log Analytics workspace ID. platform-management must have applied and this run's token needs output-read access to it (tfe_outputs does not need remote state sharing), or set log_analytics_workspace_id explicitly. Management workspace: ${var.management_workspace_name}."
    }

    precondition {
      condition     = !var.use_tfe_outputs || local.manage_onboarding || local.management_onboarded
      error_message = "platform-management has not published sentinel_onboarding_id, so Sentinel does not look onboarded on the central workspace. Enable sentinel in platform-management first, or set sentinel.manage_onboarding = true here (and keep it off in platform-management - one state may own the onboarding)."
    }
  }
}

module "sentinel_content" {
  source = "../../../../patterns/terraform-azurerm-compeer-sentinel-content"
  count  = local.enabled ? 1 : 0

  log_analytics_workspace_id  = local.log_analytics_workspace_id
  tenant_id                   = var.tenant_id
  manage_onboarding           = local.manage_onboarding
  externally_provided_sources = try(var.sentinel.externally_provided_sources, [])
  enforce_source_dependencies = try(var.sentinel.enforce_source_dependencies, true)
  data_connectors             = try(var.sentinel.data_connectors, {})
  ingestion                   = try(var.sentinel.ingestion, null)
  taxii_passwords             = var.taxii_passwords
  scheduled_rules             = try(var.sentinel.scheduled_rules, {})
  nrt_rules                   = try(var.sentinel.nrt_rules, {})
  microsoft_incident_rules    = try(var.sentinel.microsoft_incident_rules, {})
  template_rules              = try(var.sentinel.template_rules, {})
  anomaly_rules               = try(var.sentinel.anomaly_rules, {})
  baseline_content            = try(var.sentinel.baseline_content, {})
  automation_rules            = try(var.sentinel.automation_rules, {})
  watchlists                  = try(var.sentinel.watchlists, {})

  depends_on = [terraform_data.platform_contract]
}
