mock_provider "azuread" {}
variables {
  client_id = "00000000-0000-0000-0000-000000000000"
}
run "create" {
  command = apply
  assert {
    condition     = length(azuread_service_principal.service_principal.feature_tags) == 0
    error_message = "no feature_tags by default"
  }
}
run "rejects_saml_without_config" {
  command = plan
  variables { preferred_single_sign_on_mode = "saml" }
  expect_failures = [azuread_service_principal.service_principal]
}
