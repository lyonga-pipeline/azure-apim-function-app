locals {
  # Caller rules win over a baseline rule with the same key (the keys are
  # prefixed, so this only matters when a caller deliberately overrides one).
  scheduled_rules = merge(local.baseline_scheduled_enabled, var.scheduled_rules)

  # Every enabled rule and the feeds it reads, for the dependency contract.
  rule_requirements = merge(
    { for key, rule in local.scheduled_rules : "scheduled/${key}" => rule.requires_sources if rule.enabled },
    { for key, rule in var.nrt_rules : "nrt/${key}" => rule.requires_sources if rule.enabled },
    { for key, rule in var.microsoft_incident_rules : "microsoft-incident/${key}" => rule.requires_sources if rule.enabled },
    { for key, rule in var.template_rules : "template/${key}" => rule.requires_sources if rule.enabled },
  )
  unmet_sources = {
    for key, required in local.rule_requirements :
    key => sort(tolist(setsubtract(toset(required), local.available_sources)))
    if length(setsubtract(toset(required), local.available_sources)) > 0
  }
}

resource "azurerm_sentinel_alert_rule_scheduled" "scheduled" {
  for_each = local.scheduled_rules

  name                       = each.key
  log_analytics_workspace_id = local.workspace_id
  display_name               = each.value.display_name
  description                = each.value.description
  severity                   = each.value.severity
  query                      = each.value.query
  query_frequency            = each.value.query_frequency
  query_period               = each.value.query_period
  trigger_operator           = each.value.trigger_operator
  trigger_threshold          = each.value.trigger_threshold
  tactics                    = each.value.tactics
  techniques                 = each.value.techniques
  enabled                    = each.value.enabled
  custom_details             = length(each.value.custom_details) == 0 ? null : each.value.custom_details
  suppression_enabled        = each.value.suppression_duration != null
  suppression_duration       = each.value.suppression_duration

  event_grouping {
    aggregation_method = each.value.event_grouping
  }

  dynamic "entity_mapping" {
    for_each = each.value.entity_mappings
    content {
      entity_type = entity_mapping.value.entity_type
      dynamic "field_mapping" {
        for_each = entity_mapping.value.field_mappings
        content {
          identifier  = field_mapping.value.identifier
          column_name = field_mapping.value.column_name
        }
      }
    }
  }

  dynamic "alert_details_override" {
    for_each = each.value.alert_details_override == null ? [] : [each.value.alert_details_override]
    content {
      display_name_format  = alert_details_override.value.display_name_format
      description_format   = alert_details_override.value.description_format
      severity_column_name = alert_details_override.value.severity_column_name
      tactics_column_name  = alert_details_override.value.tactics_column_name
    }
  }

  dynamic "incident" {
    for_each = each.value.incident.create ? [each.value.incident] : []
    content {
      create_incident_enabled = true
      grouping {
        enabled                 = incident.value.grouping.enabled
        lookback_duration       = incident.value.grouping.lookback_duration
        reopen_closed_incidents = incident.value.grouping.reopen_closed_incidents
        entity_matching_method  = incident.value.grouping.entity_matching_method
        by_entities             = incident.value.grouping.entity_matching_method == "Selected" ? incident.value.grouping.by_entities : null
        by_alert_details        = incident.value.grouping.entity_matching_method == "Selected" ? incident.value.grouping.by_alert_details : null
        by_custom_details       = incident.value.grouping.entity_matching_method == "Selected" ? incident.value.grouping.by_custom_details : null
      }
    }
  }

  depends_on = [terraform_data.source_dependency_contract]
}

resource "azurerm_sentinel_alert_rule_nrt" "nrt" {
  for_each = var.nrt_rules

  name                       = each.key
  log_analytics_workspace_id = local.workspace_id
  display_name               = each.value.display_name
  description                = each.value.description
  severity                   = each.value.severity
  query                      = each.value.query
  tactics                    = each.value.tactics
  techniques                 = each.value.techniques
  enabled                    = each.value.enabled
  custom_details             = length(each.value.custom_details) == 0 ? null : each.value.custom_details
  suppression_enabled        = each.value.suppression_duration != null
  suppression_duration       = each.value.suppression_duration

  event_grouping {
    aggregation_method = each.value.event_grouping
  }

  dynamic "entity_mapping" {
    for_each = each.value.entity_mappings
    content {
      entity_type = entity_mapping.value.entity_type
      dynamic "field_mapping" {
        for_each = entity_mapping.value.field_mappings
        content {
          identifier  = field_mapping.value.identifier
          column_name = field_mapping.value.column_name
        }
      }
    }
  }

  dynamic "incident" {
    for_each = each.value.incident.create ? [each.value.incident] : []
    content {
      create_incident_enabled = true
      grouping {
        enabled                 = incident.value.grouping.enabled
        lookback_duration       = incident.value.grouping.lookback_duration
        reopen_closed_incidents = incident.value.grouping.reopen_closed_incidents
        entity_matching_method  = incident.value.grouping.entity_matching_method
        by_entities             = incident.value.grouping.entity_matching_method == "Selected" ? incident.value.grouping.by_entities : null
        by_alert_details        = incident.value.grouping.entity_matching_method == "Selected" ? incident.value.grouping.by_alert_details : null
        by_custom_details       = incident.value.grouping.entity_matching_method == "Selected" ? incident.value.grouping.by_custom_details : null
      }
    }
  }

  depends_on = [terraform_data.source_dependency_contract]
}

resource "azurerm_sentinel_alert_rule_ms_security_incident" "microsoft_incident" {
  for_each = var.microsoft_incident_rules

  name                        = each.key
  log_analytics_workspace_id  = local.workspace_id
  display_name                = each.value.display_name
  description                 = each.value.description
  product_filter              = each.value.product_filter
  severity_filter             = each.value.severity_filter
  display_name_filter         = length(each.value.display_name_filter) == 0 ? null : each.value.display_name_filter
  display_name_exclude_filter = length(each.value.display_name_exclude_filter) == 0 ? null : each.value.display_name_exclude_filter
  enabled                     = each.value.enabled

  depends_on = [terraform_data.source_dependency_contract]
}

# azurerm marks `name` on the fusion rule as deprecated (removed in provider
# v5). It is still accepted by every version this pattern allows (< 5.0), and
# the provider constraint keeps the pattern from picking up v5 unnoticed.
resource "azurerm_sentinel_alert_rule_fusion" "fusion" {
  for_each = { for key, rule in var.template_rules : key => rule if rule.kind == "fusion" }

  name                       = each.key
  log_analytics_workspace_id = local.workspace_id
  alert_rule_template_guid   = each.value.alert_rule_template
  enabled                    = each.value.enabled

  depends_on = [terraform_data.source_dependency_contract]
}

resource "azurerm_sentinel_alert_rule_threat_intelligence" "threat_intelligence" {
  for_each = { for key, rule in var.template_rules : key => rule if rule.kind == "threat_intelligence" }

  name                       = each.key
  log_analytics_workspace_id = local.workspace_id
  alert_rule_template_guid   = each.value.alert_rule_template
  enabled                    = each.value.enabled

  depends_on = [terraform_data.source_dependency_contract]
}

resource "azurerm_sentinel_alert_rule_machine_learning_behavior_analytics" "ml_behavior_analytics" {
  for_each = { for key, rule in var.template_rules : key => rule if rule.kind == "ml_behavior_analytics" }

  name                       = each.key
  log_analytics_workspace_id = local.workspace_id
  alert_rule_template_guid   = each.value.alert_rule_template
  enabled                    = each.value.enabled

  depends_on = [terraform_data.source_dependency_contract]
}

resource "azurerm_sentinel_alert_rule_anomaly_built_in" "anomaly" {
  for_each = var.anomaly_rules

  display_name               = each.value.display_name
  log_analytics_workspace_id = local.workspace_id
  mode                       = each.value.mode
  enabled                    = each.value.enabled
}
