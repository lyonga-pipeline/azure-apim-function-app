mock_provider "azurerm" {}
run "disabled_is_noop" {
  command = plan
  variables { enabled = false }
  assert {
    condition     = length(azurerm_security_center_subscription_pricing.this) == 0
    error_message = "nothing managed when enabled = false"
  }
}
