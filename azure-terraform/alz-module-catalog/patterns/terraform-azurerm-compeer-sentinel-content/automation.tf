locals {
  # Every analytic rule this pattern creates, by key, so an automation rule can
  # be scoped to rules it owns instead of hand-pasted resource IDs.
  analytic_rule_ids = merge(
    { for key, rule in azurerm_sentinel_alert_rule_scheduled.scheduled : key => rule.id },
    { for key, rule in azurerm_sentinel_alert_rule_nrt.nrt : key => rule.id },
    { for key, rule in azurerm_sentinel_alert_rule_ms_security_incident.microsoft_incident : key => rule.id },
  )

  automation_rule_conditions = {
    for key, rule in var.automation_rules : key => concat(
      [for condition in rule.conditions : {
        conditionType = "Property"
        conditionProperties = {
          propertyName   = condition.property
          operator       = condition.operator
          propertyValues = condition.values
        }
      }],
      length(rule.analytic_rule_keys) == 0 ? [] : [{
        conditionType = "Property"
        conditionProperties = {
          propertyName   = "IncidentRelatedAnalyticRuleIds"
          operator       = "Contains"
          propertyValues = [for rule_key in rule.analytic_rule_keys : lookup(local.analytic_rule_ids, rule_key, "unresolved:${rule_key}")]
        }
      }],
    )
  }
}

# Azure requires the automation rule name to be a UUID. Deriving it from the
# workspace and the rule key keeps it stable across runs without storing state.
resource "azurerm_sentinel_automation_rule" "automation" {
  for_each = var.automation_rules

  name                       = uuidv5("url", "sentinel-automation/${lower(var.log_analytics_workspace_id)}/${each.key}")
  log_analytics_workspace_id = local.workspace_id
  display_name               = each.value.display_name
  order                      = each.value.order
  enabled                    = each.value.enabled
  triggers_on                = each.value.triggers_on
  triggers_when              = each.value.triggers_when
  expiration                 = each.value.expiration
  condition_json             = length(local.automation_rule_conditions[each.key]) == 0 ? null : jsonencode(local.automation_rule_conditions[each.key])

  dynamic "action_incident" {
    for_each = each.value.modify_incident
    content {
      order                  = action_incident.value.order
      status                 = action_incident.value.status
      severity               = action_incident.value.severity
      labels                 = action_incident.value.labels
      owner_id               = action_incident.value.owner_id
      classification         = action_incident.value.classification
      classification_comment = action_incident.value.classification_comment
    }
  }

  dynamic "action_incident_task" {
    for_each = each.value.incident_tasks
    content {
      order       = action_incident_task.value.order
      title       = action_incident_task.value.title
      description = action_incident_task.value.description
    }
  }

  dynamic "action_playbook" {
    for_each = each.value.playbooks
    content {
      order        = action_playbook.value.order
      logic_app_id = action_playbook.value.logic_app_id
      tenant_id    = coalesce(action_playbook.value.tenant_id, var.tenant_id)
    }
  }

  lifecycle {
    precondition {
      condition     = alltrue([for rule_key in each.value.analytic_rule_keys : contains(keys(local.analytic_rule_ids), rule_key)])
      error_message = "automation_rules.${each.key}.analytic_rule_keys must name rules created by this pattern (scheduled_rules, nrt_rules, microsoft_incident_rules or enabled baseline rules)."
    }
  }
}
