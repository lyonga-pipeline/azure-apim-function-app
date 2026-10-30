# PHASE2 EXISTING: IAM-05 separation of environment and plan/apply identity boundaries.
mock_provider "azurerm" {}
mock_provider "azuread" {}
run "four_federated_identities_keep_prod_and_apply_privileges_separate" {
  command = plan
  variables {
    workload_identities = { for key in ["prod-plan", "prod-apply", "nonprod-plan", "nonprod-apply"] : key => {
      display_name = "example-${key}"
      federated_credentials = { hcp = {
        display_name = "hcp-${key}"
        issuer       = "https://app.terraform.io"
        subject      = "organization:example:project:applications:workspace:app-${split("-", key)[0]}:run_phase:${split("-", key)[1]}"
      } }
      azure_role_assignments = { scoped = {
        scope                = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/app-${split("-", key)[0]}-rg"
        role_definition_name = endswith(key, "plan") ? "Reader" : "Contributor"
      } }
    } }
  }
  assert {
    condition     = length(module.service_principal) == 4 && length(azuread_application_federated_identity_credential.federated_credential) == 4 && length(azurerm_role_assignment.assignment) == 4
    error_message = "Environment and plan/apply separation must not collapse into a shared privileged principal."
  }
}
run "wildcard_subject_is_not_a_valid_exact_trust" {
  command = plan
  variables {
    workload_identities = { invalid = {
      display_name          = "invalid"
      federated_credentials = { hcp = { display_name = "invalid", issuer = "https://app.terraform.io", subject = "organization:example:workspace:*" } }
    } }
  }
  expect_failures = [var.workload_identities]
}
