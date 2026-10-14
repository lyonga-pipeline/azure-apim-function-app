mock_provider "azurerm" {}

variables {
  name                = "appi-orders"
  resource_group_name = "rg-app"
  location            = "eastus2"
  application_type    = "web"
}

run "create" {
  command = apply
  assert {
    condition     = azurerm_application_insights.application_insights.application_type == "web"
    error_message = "application_type not wired"
  }
  assert {
    condition = (
      azurerm_application_insights.application_insights.daily_data_cap_notifications_enabled &&
      azurerm_application_insights.application_insights.ip_masking_enabled &&
      azurerm_application_insights.application_insights.local_authentication_enabled &&
      !output.security_configuration.local_authentication_disabled
    )
    error_message = "Null legacy inputs must preserve the existing provider defaults through non-deprecated attributes."
  }
}

run "legacy_true_flags_are_inverted_without_changing_resource_identity" {
  command = plan
  variables {
    daily_data_cap_notifications_disabled = true
    disable_ip_masking                    = true
    local_authentication_disabled         = true
  }
  assert {
    condition = (
      !azurerm_application_insights.application_insights.daily_data_cap_notifications_enabled &&
      !azurerm_application_insights.application_insights.ip_masking_enabled &&
      !azurerm_application_insights.application_insights.local_authentication_enabled &&
      output.security_configuration.local_authentication_disabled &&
      azurerm_application_insights.application_insights.name == var.name
    )
    error_message = "Existing disabled=true callers must retain the inverse configuration and the same resource name."
  }
}

run "legacy_false_flags_keep_features_enabled" {
  command = plan
  variables {
    daily_data_cap_notifications_disabled = false
    disable_ip_masking                    = false
    local_authentication_disabled         = false
  }
  assert {
    condition = (
      output.security_configuration.daily_data_cap_notifications_enabled &&
      output.security_configuration.ip_masking_enabled &&
      !output.security_configuration.local_authentication_disabled
    )
    error_message = "Existing disabled=false callers must not have their boolean meaning reversed during migration."
  }
}
