data "tfe_outputs" "management" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.management_workspace_name
}

data "tfe_outputs" "connectivity" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.connectivity_workspace_name
}

resource "time_static" "deployment_created" {}

locals {
  enabled = try(var.cloudflare_connectors.enabled, false)

  # This workspace owns the deployment-lifecycle boundary for every resource
  # it creates, so it - not the tags module - owns created_on's stability.
  # time_static computes its value once, on first apply, and stores it in
  # state; every later plan reuses the same value instead of recomputing it
  # (unlike timestamp(), which would re-diff this tag on every single plan).
  # This intentionally supersedes any created_on set in platform_tags below.
  deployment_created_on = formatdate("YYYY-MM-DD", time_static.deployment_created.rfc3339)

  management_outputs = merge(
    try(data.tfe_outputs.management[0].nonsensitive_values, {}),
    try(data.tfe_outputs.management[0].values, {})
  )

  connectivity_outputs = merge(
    try(data.tfe_outputs.connectivity[0].nonsensitive_values, {}),
    try(data.tfe_outputs.connectivity[0].values, {})
  )

  log_analytics_workspace_id = try(coalesce(var.log_analytics_workspace_id, try(local.management_outputs.log_analytics_workspace_id, null)), null)

  connectors = {
    for key, connector in try(var.cloudflare_connectors.connectors, {}) : key => merge(connector, {
      subnet_id = coalesce(
        try(connector.subnet_id, null),
        try(local.connectivity_outputs.subnet_ids[connector.subnet_key], null),
        try(local.connectivity_outputs.subnet_ids["prod-cftagent-subnet"], null)
      )
      diagnostics = (
        coalesce(try(connector.diagnostics.enabled, null), false) &&
        local.log_analytics_workspace_id != null &&
        try(connector.diagnostics.log_analytics_workspace_id, null) == null
        ) ? merge(try(connector.diagnostics, {}), {
          log_analytics_workspace_id = local.log_analytics_workspace_id
      }) : try(connector.diagnostics, {})
    })
  }
}

module "cloudflare_connectors" {
  source = "../../../../patterns/terraform-azurerm-compeer-cloudflare-connectors"
  count  = local.enabled ? 1 : 0

  providers = {
    azurerm = azurerm
  }

  subscription_id              = var.subscription_id
  location                     = var.location
  environment                  = var.environment
  platform_tags                = merge(var.platform_tags, try(var.cloudflare_connectors.platform_tags, {}), { created_on = local.deployment_created_on })
  resource_group               = merge({ name = local.std_names.resource_group }, try(var.cloudflare_connectors.resource_group, {}))
  connectors                   = local.connectors
  admin_passwords              = var.admin_passwords
  custom_data_by_key           = var.custom_data_by_key
  extension_protected_settings = var.extension_protected_settings
  role_assignments             = try(var.cloudflare_connectors.role_assignments, {})
  management_locks             = try(var.cloudflare_connectors.management_locks, {})
  additional_scopes            = try(var.cloudflare_connectors.additional_scopes, {})
  operational_contracts        = try(var.cloudflare_connectors.operational_contracts, {})
}

# =============================================================================
# PHASE 2 CHANGES - additive, opt-in; preserve existing resource/state ownership.
# Adopt this marked section with phase2_*.tf, phase2-tests/ and phase2.tfvars.example.
# =============================================================================

locals {
  # New composition consumes public resource contracts, never sensitive output maps.
  phase2_log_analytics_workspace_id = try(coalesce(
    var.log_analytics_workspace_id,
    try(data.tfe_outputs.management[0].nonsensitive_values.log_analytics_workspace_id, null)
  ), null)
}
resource "terraform_data" "phase2_agent_contract" {
  count = length(var.phase2_agents) > 0 ? 1 : 0
  lifecycle {
    precondition {
      condition     = local.enabled && local.phase2_log_analytics_workspace_id != null && var.phase2_agent_ownership_confirmed
      error_message = "Phase 2 agents require this VM owner, central LAW and confirmed extension/DCR/DCE association ownership."
    }
    precondition {
      condition = alltrue([for key, agent in var.phase2_agents :
        contains(keys(try(var.cloudflare_connectors.connectors, {})), key) && agent.os_type == "Linux" &&
        try(contains(var.cloudflare_connectors.connectors[key].identity.identity_ids, agent.managed_identity_id), false)
      ])
      error_message = "Each agent key must identify this root's Linux VM, with the declared UAMI already assigned in its identity configuration."
    }
    precondition {
      condition = alltrue([for key, agent in var.phase2_agents : !agent.install_agent || alltrue([
        for extension in values(try(var.cloudflare_connectors.connectors[key].extensions, {})) : extension.type != "AzureMonitorLinuxAgent"
      ])])
      error_message = "The connector's existing extension map already owns AMA. Reuse it with install_agent=false; do not define a second extension."
    }
  }
}
module "phase2_vm_observability" {
  source                     = "../../../../patterns/terraform-azurerm-compeer-platform-observability"
  count                      = local.enabled && length(var.phase2_agents) > 0 ? 1 : 0
  resource_group_name        = module.cloudflare_connectors[0].resource_group_name
  location                   = var.location
  log_analytics_workspace_id = coalesce(local.phase2_log_analytics_workspace_id, "unset")
  agents = { for key, agent in var.phase2_agents : key => merge(agent, {
    virtual_machine_id = module.cloudflare_connectors[0].connector_vm_ids[key]
  }) if contains(keys(try(var.cloudflare_connectors.connectors, {})), key) }
  tags       = module.cloudflare_connectors[0].resource_tags
  depends_on = [terraform_data.phase2_agent_contract]
}
