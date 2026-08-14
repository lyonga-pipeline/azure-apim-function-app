locals {
  criteria_mode_count = length(compact([
    length(var.criteria) > 0 ? "criteria" : null,
    var.dynamic_criteria == null ? null : "dynamic",
    var.application_insights_web_test_location_availability_criteria == null ? null : "webtest",
  ]))
}

resource "azurerm_monitor_metric_alert" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  scopes                   = var.scopes
  description              = var.description
  enabled                  = var.enabled
  auto_mitigate            = var.auto_mitigate
  severity                 = var.severity
  frequency                = var.frequency
  window_size              = var.window_size
  target_resource_type     = var.target_resource_type
  target_resource_location = var.target_resource_location
  tags                     = var.tags

  dynamic "criteria" {
    for_each = var.criteria
    content {
      metric_namespace       = criteria.value.metric_namespace
      metric_name            = criteria.value.metric_name
      aggregation            = criteria.value.aggregation
      operator               = criteria.value.operator
      threshold              = criteria.value.threshold
      skip_metric_validation = try(criteria.value.skip_metric_validation, null)

      dynamic "dimension" {
        for_each = try(criteria.value.dimensions, {})
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "dynamic_criteria" {
    for_each = var.dynamic_criteria == null ? [] : [var.dynamic_criteria]
    content {
      metric_namespace         = dynamic_criteria.value.metric_namespace
      metric_name              = dynamic_criteria.value.metric_name
      aggregation              = dynamic_criteria.value.aggregation
      operator                 = dynamic_criteria.value.operator
      alert_sensitivity        = dynamic_criteria.value.alert_sensitivity
      evaluation_total_count   = try(dynamic_criteria.value.evaluation_total_count, null)
      evaluation_failure_count = try(dynamic_criteria.value.evaluation_failure_count, null)
      ignore_data_before       = try(dynamic_criteria.value.ignore_data_before, null)
      skip_metric_validation   = try(dynamic_criteria.value.skip_metric_validation, null)

      dynamic "dimension" {
        for_each = try(dynamic_criteria.value.dimensions, {})
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "application_insights_web_test_location_availability_criteria" {
    for_each = var.application_insights_web_test_location_availability_criteria == null ? [] : [var.application_insights_web_test_location_availability_criteria]
    content {
      component_id          = application_insights_web_test_location_availability_criteria.value.component_id
      web_test_id           = application_insights_web_test_location_availability_criteria.value.web_test_id
      failed_location_count = application_insights_web_test_location_availability_criteria.value.failed_location_count
    }
  }

  dynamic "action" {
    for_each = var.actions
    content {
      action_group_id    = action.value.action_group_id
      webhook_properties = try(action.value.webhook_properties, null)
    }
  }

  lifecycle {
    precondition {
      condition     = local.criteria_mode_count == 1
      error_message = "Set exactly one criteria mode: criteria, dynamic_criteria, or application_insights_web_test_location_availability_criteria."
    }
  }
}
