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
  use_existing                  = var.use_existing

  dynamic "feature_tags" {
    for_each = var.feature_tags
    content {
      custom_single_sign_on = feature_tags.value.custom_single_sign_on
      enterprise            = feature_tags.value.enterprise
      gallery               = feature_tags.value.gallery
      hide                  = feature_tags.value.hide
    }
  }

  dynamic "saml_single_sign_on" {
    for_each = var.saml_single_sign_on
    content {
      relay_state = saml_single_sign_on.value.relay_state
    }
  }
}
