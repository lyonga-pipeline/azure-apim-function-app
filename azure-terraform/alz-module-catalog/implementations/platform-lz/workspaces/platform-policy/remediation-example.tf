# Existing-resource remediation example AND implementation for this workspace.
# WHY: assigning DINE evaluates existing subscriptions but does not backfill them.
# Empty targets below create no jobs. This does not add plans, assignments, tags,
# locks, security contacts, exemptions, or changes to Terraform-owned diagnostics.
#
# Set this separate HCP Terraform variable (HCL enabled), or append it as a
# top-level value in terraform.tfvars. Do not replace the existing policy object.
# Select only approved plans already enabled in policy.defender_for_cloud_policy.
#
# existing_resource_remediation = {
#   batch_name = "pilot-20261014"
#   defender_targets = {
#     security = {
#       subscription_id = "REPLACE_SECURITY_SUBSCRIPTION_UUID"
#       plan_keys = [
#         "defender_servers", "defender_storage", "defender_key_vault",
#         "defender_app_services", "defender_sql_databases",
#         "defender_sql_servers_on_machines", "defender_containers",
#         "defender_resource_manager",
#       ]
#     }
#     network = {
#       subscription_id = "REPLACE_NETWORK_SUBSCRIPTION_UUID"
#       plan_keys = ["defender_servers", "defender_key_vault"] # Expand only after approval.
#     }
#   }
#   flow_log_targets = {
#     network = { subscription_id = "REPLACE_NETWORK_SUBSCRIPTION_UUID", resource_count = 1 }
#   }
# }
#
# Related changes and WHY:
# - locals.tf merges these jobs with existing manually approved tasks, not plans.
# - main.tf checks this batch before invoking the existing policy pattern.
# - pattern variables/remediation.tf add subscription-scoped tasks so a pilot
#   cannot accidentally backfill another subscription in the enterprise MG.
# - pattern outputs retain remediation_task_ids for both existing MG/new sub jobs.
#
# Before apply: verify applied assignment IDs/exclusions, paid-plan approval,
# Microsoft.Security/Network/PolicyInsights registration, identity RBAC propagation,
# correct regional Network Watcher, storage/workspace access and current compliance.
# A resource limit is a cap, NOT an exact VNet allowlist. For one specific VNet,
# verify it is the only applicable noncompliant VNet in this subscription/region.
# Keep this batch name stable; approve a new name to intentionally rerun a job.
# A task ID or successful apply is not proof of compliance or actual log ingestion.

variable "existing_resource_remediation" {
  description = "Opt-in backfill of existing resources using already-enabled Defender/flow assignments. Empty targets are a no-op; do not select the Terraform-managed management subscription for Defender."
  type = object({
    batch_name = optional(string, "existing-pilot")
    defender_targets = optional(map(object({
      subscription_id = string
      plan_keys       = set(string)
    })), {})
    flow_log_targets = optional(map(object({
      subscription_id = string
      resource_count  = optional(number, 1)
    })), {})
  })
  default = {}

  validation {
    condition = (
      can(regex("^[a-z][a-z0-9-]{0,19}$", var.existing_resource_remediation.batch_name)) &&
      alltrue([for key in concat(keys(var.existing_resource_remediation.defender_targets), keys(var.existing_resource_remediation.flow_log_targets)) : can(regex("^[a-z][a-z0-9-]{0,11}$", key))])
    )
    error_message = "Use a stable lowercase batch_name of 1-20 characters and target keys of 1-12 characters, starting with a letter (letters, digits, hyphens)."
  }

  validation {
    condition = alltrue([for target in concat(values(var.existing_resource_remediation.defender_targets), values(var.existing_resource_remediation.flow_log_targets)) :
      can(regex("(?i)^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$", target.subscription_id)) &&
      target.subscription_id != "00000000-0000-0000-0000-000000000000"
    ])
    error_message = "Backfill targets require actual nonzero subscription UUIDs, not names, ARM paths or REPLACE placeholders."
  }

  validation {
    condition = alltrue([for target in values(var.existing_resource_remediation.defender_targets) :
      length(target.plan_keys) > 0 && alltrue([for key in target.plan_keys : contains([
        "defender_servers", "defender_storage", "defender_key_vault", "defender_app_services",
        "defender_sql_databases", "defender_sql_servers_on_machines", "defender_containers", "defender_resource_manager"
      ], key)])
    ])
    error_message = "Select an explicit non-empty subset of the eight existing Defender assignment keys. Tags, CIS, diagnostic audits and unapproved extra plans are not backfill options."
  }

  validation {
    condition = (
      length(distinct([for target in values(var.existing_resource_remediation.defender_targets) : lower(target.subscription_id)])) == length(var.existing_resource_remediation.defender_targets) &&
      length(distinct([for target in values(var.existing_resource_remediation.flow_log_targets) : lower(target.subscription_id)])) == length(var.existing_resource_remediation.flow_log_targets) &&
      alltrue([for target in values(var.existing_resource_remediation.flow_log_targets) : target.resource_count >= 1 && target.resource_count <= 100 && floor(target.resource_count) == target.resource_count])
    )
    error_message = "Use one entry per subscription per control, with an explicit flow-log cap of 1-100 resources."
  }
}

locals {
  # Defender targets are subscriptions, not regional resources: never use a location filter here.
  existing_resource_defender_tasks = merge([for target_key, target in var.existing_resource_remediation.defender_targets : {
    for plan_key in target.plan_keys : "${var.existing_resource_remediation.batch_name}-${target_key}-${trimprefix(plan_key, "defender_")}" => {
      assignment_key                 = plan_key
      subscription_id                = "/subscriptions/${lower(target.subscription_id)}"
      policy_definition_reference_id = null
      location_filters               = null
      resource_discovery_mode        = "ReEvaluateCompliance"
      resource_count                 = 1
      parallel_deployments           = 1
      failure_percentage             = 0
    }
  }]...)

  # Network Watcher already reports compliant in the supplied evidence; do not redeploy it.
  existing_resource_flow_tasks = {
    for target_key, target in var.existing_resource_remediation.flow_log_targets : "${var.existing_resource_remediation.batch_name}-${target_key}-vnet-flow" => {
      assignment_key                 = "vnet_flow_logs_traffic_analytics"
      subscription_id                = "/subscriptions/${lower(target.subscription_id)}"
      policy_definition_reference_id = null
      location_filters               = [coalesce(try(local.network_flow_logging_policy.vnet_region, null), var.location)]
      resource_discovery_mode        = "ReEvaluateCompliance"
      resource_count                 = target.resource_count
      parallel_deployments           = 1
      failure_percentage             = 0
    }
  }
  existing_resource_tasks = merge(local.existing_resource_defender_tasks, local.existing_resource_flow_tasks)
}

resource "terraform_data" "existing_resource_remediation_contract" {
  count = length(local.existing_resource_tasks) > 0 ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.enabled && try(local.remediation.enabled, false)
      error_message = "Backfill targets require policy and its existing DINE bundle to be enabled."
    }
    precondition {
      condition     = length(setintersection(toset(keys(local.existing_resource_tasks)), toset(keys(try(var.policy.remediation.tasks, {}))))) == 0
      error_message = "A generated backfill task name collides with policy.remediation.tasks. Use a distinct approved batch name; do not silently replace a task."
    }
  }
}
