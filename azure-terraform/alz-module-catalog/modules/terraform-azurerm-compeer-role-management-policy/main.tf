resource "azurerm_role_management_policy" "this" {
  for_each = var.policies

  role_definition_id = each.value.role_definition_id
  scope              = each.value.scope

  dynamic "activation_rules" {
    for_each = each.value.activation_rules == null ? [] : [each.value.activation_rules]
    content {
      maximum_duration                                   = try(activation_rules.value.maximum_duration, null)
      require_approval                                   = try(activation_rules.value.require_approval, null)
      require_justification                              = try(activation_rules.value.require_justification, null)
      require_multifactor_authentication                 = try(activation_rules.value.require_multifactor_authentication, null)
      require_ticket_info                                = try(activation_rules.value.require_ticket_info, null)
      required_conditional_access_authentication_context = try(activation_rules.value.required_conditional_access_authentication_context, null)

      dynamic "approval_stage" {
        for_each = length(try(activation_rules.value.approvers, [])) == 0 ? [] : [activation_rules.value.approvers]
        content {
          dynamic "primary_approver" {
            for_each = { for a in approval_stage.value : "${a.type}:${a.object_id}" => a }
            content {
              object_id = primary_approver.value.object_id
              type      = primary_approver.value.type
            }
          }
        }
      }
    }
  }

  dynamic "active_assignment_rules" {
    for_each = each.value.active_assignment_rules == null ? [] : [each.value.active_assignment_rules]
    content {
      expiration_required                = try(active_assignment_rules.value.expiration_required, null)
      expire_after                       = try(active_assignment_rules.value.expire_after, null)
      require_justification              = try(active_assignment_rules.value.require_justification, null)
      require_multifactor_authentication = try(active_assignment_rules.value.require_multifactor_authentication, null)
      require_ticket_info                = try(active_assignment_rules.value.require_ticket_info, null)
    }
  }

  dynamic "eligible_assignment_rules" {
    for_each = each.value.eligible_assignment_rules == null ? [] : [each.value.eligible_assignment_rules]
    content {
      expiration_required = try(eligible_assignment_rules.value.expiration_required, null)
      expire_after        = try(eligible_assignment_rules.value.expire_after, null)
    }
  }

  dynamic "notification_rules" {
    for_each = length(try(each.value.notification_rules, {})) == 0 ? [] : [each.value.notification_rules]
    content {
      dynamic "active_assignments" {
        for_each = try(notification_rules.value.active_assignments, null) == null ? [] : [notification_rules.value.active_assignments]
        content {
          dynamic "admin_notifications" {
            for_each = try(active_assignments.value.admin_notifications, null) == null ? [] : [active_assignments.value.admin_notifications]
            content {
              default_recipients    = admin_notifications.value.default_recipients
              notification_level    = try(admin_notifications.value.notification_level, "All")
              additional_recipients = try(admin_notifications.value.additional_recipients, [])
            }
          }
          dynamic "approver_notifications" {
            for_each = try(active_assignments.value.approver_notifications, null) == null ? [] : [active_assignments.value.approver_notifications]
            content {
              default_recipients    = approver_notifications.value.default_recipients
              notification_level    = try(approver_notifications.value.notification_level, "All")
              additional_recipients = try(approver_notifications.value.additional_recipients, [])
            }
          }
          dynamic "assignee_notifications" {
            for_each = try(active_assignments.value.assignee_notifications, null) == null ? [] : [active_assignments.value.assignee_notifications]
            content {
              default_recipients    = assignee_notifications.value.default_recipients
              notification_level    = try(assignee_notifications.value.notification_level, "All")
              additional_recipients = try(assignee_notifications.value.additional_recipients, [])
            }
          }
        }
      }

      dynamic "eligible_activations" {
        for_each = try(notification_rules.value.eligible_activations, null) == null ? [] : [notification_rules.value.eligible_activations]
        content {
          dynamic "admin_notifications" {
            for_each = try(eligible_activations.value.admin_notifications, null) == null ? [] : [eligible_activations.value.admin_notifications]
            content {
              default_recipients    = admin_notifications.value.default_recipients
              notification_level    = try(admin_notifications.value.notification_level, "All")
              additional_recipients = try(admin_notifications.value.additional_recipients, [])
            }
          }
          dynamic "approver_notifications" {
            for_each = try(eligible_activations.value.approver_notifications, null) == null ? [] : [eligible_activations.value.approver_notifications]
            content {
              default_recipients    = approver_notifications.value.default_recipients
              notification_level    = try(approver_notifications.value.notification_level, "All")
              additional_recipients = try(approver_notifications.value.additional_recipients, [])
            }
          }
          dynamic "assignee_notifications" {
            for_each = try(eligible_activations.value.assignee_notifications, null) == null ? [] : [eligible_activations.value.assignee_notifications]
            content {
              default_recipients    = assignee_notifications.value.default_recipients
              notification_level    = try(assignee_notifications.value.notification_level, "All")
              additional_recipients = try(assignee_notifications.value.additional_recipients, [])
            }
          }
        }
      }

      dynamic "eligible_assignments" {
        for_each = try(notification_rules.value.eligible_assignments, null) == null ? [] : [notification_rules.value.eligible_assignments]
        content {
          dynamic "admin_notifications" {
            for_each = try(eligible_assignments.value.admin_notifications, null) == null ? [] : [eligible_assignments.value.admin_notifications]
            content {
              default_recipients    = admin_notifications.value.default_recipients
              notification_level    = try(admin_notifications.value.notification_level, "All")
              additional_recipients = try(admin_notifications.value.additional_recipients, [])
            }
          }
          dynamic "approver_notifications" {
            for_each = try(eligible_assignments.value.approver_notifications, null) == null ? [] : [eligible_assignments.value.approver_notifications]
            content {
              default_recipients    = approver_notifications.value.default_recipients
              notification_level    = try(approver_notifications.value.notification_level, "All")
              additional_recipients = try(approver_notifications.value.additional_recipients, [])
            }
          }
          dynamic "assignee_notifications" {
            for_each = try(eligible_assignments.value.assignee_notifications, null) == null ? [] : [eligible_assignments.value.assignee_notifications]
            content {
              default_recipients    = assignee_notifications.value.default_recipients
              notification_level    = try(assignee_notifications.value.notification_level, "All")
              additional_recipients = try(assignee_notifications.value.additional_recipients, [])
            }
          }
        }
      }
    }
  }
}
