# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azurerm_security_center_subscription_pricing.this
  to   = azurerm_security_center_subscription_pricing.pricing
}

moved {
  from = azurerm_security_center_contact.this
  to   = azurerm_security_center_contact.contact
}

moved {
  from = azurerm_security_center_setting.this
  to   = azurerm_security_center_setting.setting
}
