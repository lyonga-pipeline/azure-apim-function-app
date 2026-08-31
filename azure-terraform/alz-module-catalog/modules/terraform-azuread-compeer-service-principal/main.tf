resource "azuread_service_principal" "service_principal" {
  client_id                     = var.client_id
  account_enabled               = var.account_enabled
  alternative_names             = var.alternative_names
  app_role_assignment_required  = var.app_role_assignment_required
  description                   = var.description
  login_url                     = var.login_url
  notes                         = var.notes
  notification_email_addresses  = var.notification_email_addresses
  owners                        = var.owners
  preferred_single_sign_on_mode = var.preferred_single_sign_on_mode
  tags                          = var.tags

  dynamic "feature_tags" {
    for_each = var.feature_tags == null ? [] : [var.feature_tags]
    content {
      custom_single_sign_on = try(feature_tags.value.custom_single_sign_on, null)
      enterprise            = try(feature_tags.value.enterprise, null)
      gallery               = try(feature_tags.value.gallery, null)
      hide                  = try(feature_tags.value.hide, null)
    }
  }

  dynamic "saml_single_sign_on" {
    for_each = var.saml_single_sign_on == null ? [] : [var.saml_single_sign_on]
    content {
      relay_state = try(saml_single_sign_on.value.relay_state, null)
    }
  }

  lifecycle {
    precondition {
      condition     = var.feature_tags == null || length(var.tags) == 0
      error_message = "feature_tags and tags cannot be configured together."
    }
    precondition {
      condition     = var.preferred_single_sign_on_mode != "saml" || var.saml_single_sign_on != null
      error_message = "preferred_single_sign_on_mode = saml requires saml_single_sign_on configuration."
    }
  }
}
