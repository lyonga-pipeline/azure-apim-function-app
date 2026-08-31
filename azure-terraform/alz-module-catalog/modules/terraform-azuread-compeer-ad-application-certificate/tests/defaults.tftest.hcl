mock_provider "azuread" {}
variables {
  application_id = "/applications/11111111-1111-1111-1111-111111111111"
  type           = "AsymmetricX509Cert"
  value          = "base64-cert-data=="
}
run "create" {
  command = apply
  assert {
    condition     = azuread_application_certificate.ad_application_certificate.type == "AsymmetricX509Cert"
    error_message = "type not wired"
  }
}
run "rejects_no_application" {
  command = plan
  variables {
    application_id        = null
    application_object_id = null
  }
  expect_failures = [azuread_application_certificate.ad_application_certificate]
}
