mock_provider "azurerm" {}
run "empty_is_noop" {
  command = plan
  assert {
    condition     = length(azurerm_policy_definition.definition) == 0 && length(azurerm_policy_set_definition.initiative) == 0
    error_message = "nothing managed by default"
  }
}
