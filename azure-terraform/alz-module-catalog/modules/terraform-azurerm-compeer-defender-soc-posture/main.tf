# ============================================================================
# PATTERN MODULE: composes subscription security posture controls; coordinate ownership with Azure Policy/Defender governance.
# ============================================================================

locals {
  contract = {
    enabled                       = var.enabled
    defender_standard_enabled     = coalesce(try(var.posture_contract.defender_standard_enabled, null), false)
    sentinel_enabled              = coalesce(try(var.posture_contract.sentinel_enabled, null), false)
    data_collection_rules_enabled = coalesce(try(var.posture_contract.data_collection_rules_enabled, null), false)
    security_contact_enabled      = coalesce(try(var.posture_contract.security_contact_enabled, null), false)
    notes                         = try(var.posture_contract.notes, null)
  }
}

resource "azurerm_security_center_subscription_pricing" "this" {
  for_each = var.enabled ? var.defender_plans : {}

  resource_type = each.value.resource_type
  tier          = try(each.value.tier, "Standard")
  subplan       = try(each.value.subplan, null)

  dynamic "extension" {
    for_each = try(each.value.extensions, {})
    content {
      name                            = extension.value.name
      additional_extension_properties = try(extension.value.additional_extension_properties, null)
    }
  }
}

resource "azurerm_security_center_contact" "this" {
  count = var.enabled && var.security_contact != null ? 1 : 0

  name                = try(var.security_contact.name, "default")
  email               = var.security_contact.email
  phone               = try(var.security_contact.phone, null)
  alert_notifications = try(var.security_contact.alert_notifications, true)
  alerts_to_admins    = try(var.security_contact.alerts_to_admins, true)
}

resource "azurerm_security_center_setting" "this" {
  for_each = var.enabled ? var.security_center_settings : {}

  setting_name = each.key
  enabled      = each.value.enabled
}

resource "terraform_data" "posture_contract" {
  input = local.contract

  lifecycle {
    precondition {
      condition     = !local.contract.defender_standard_enabled || length(var.defender_plans) > 0
      error_message = "Defender Standard posture cannot be marked enabled unless defender_plans is populated."
    }

    precondition {
      condition     = !local.contract.security_contact_enabled || var.security_contact != null
      error_message = "Security contact posture cannot be marked enabled unless security_contact is configured."
    }
  }
}
