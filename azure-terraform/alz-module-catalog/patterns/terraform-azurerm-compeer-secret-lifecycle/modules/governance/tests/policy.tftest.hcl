mock_provider "azurerm" {}
variables { subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000001" }
run "central_policies_not_duplicated_by_default" {
  command = plan
  assert {
    condition     = length(azurerm_subscription_policy_assignment.vault) == 0
    error_message = "Do not silently duplicate inherited central policies."
  }
}
run "reject_identityless_deployment_effect" {
  command = plan
  variables {
    policies = { expiry = { name = "expiry", definition_id = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000001", parameters = "{\"effect\":{\"value\":\"DeployIfNotExists\"}}" } }
  }
  expect_failures = [var.policies]
}
