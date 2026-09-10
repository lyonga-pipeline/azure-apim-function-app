mock_provider "azurerm" {}
mock_provider "azuread" {}

run "empty_is_noop" {
  command = plan
  assert {
    condition     = length(module.application) == 0 && length(azuread_application_federated_identity_credential.this) == 0
    error_message = "no identities by default"
  }
}

run "app_sp_fic_and_rbac" {
  command = plan
  variables {
    workload_identities = {
      governance = {
        display_name = "platform-compeer-governance-oidc"
        federated_credentials = {
          plan = {
            display_name = "hcp-governance-plan"
            issuer       = "https://app.terraform.io"
            subject      = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-governance:run_phase:plan"
          }
          apply = {
            display_name = "hcp-governance-apply"
            issuer       = "https://app.terraform.io"
            subject      = "organization:Compeer-Financial-Services:project:Platform-Landing-Zone:workspace:platform-governance:run_phase:apply"
          }
        }
        azure_role_assignments = {
          mg_contributor = {
            scope                = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg"
            role_definition_name = "Management Group Contributor"
          }
        }
      }
    }
  }
  assert {
    condition     = length(module.application) == 1 && length(module.service_principal) == 1
    error_message = "one app + one SP per identity"
  }
  assert {
    condition     = length(azuread_application_federated_identity_credential.this) == 2
    error_message = "one FIC per federated_credentials entry"
  }
  assert {
    condition     = length(azurerm_role_assignment.this) == 1
    error_message = "one SP role assignment"
  }
}

run "rejects_more_than_20_fics" {
  command = plan
  variables {
    workload_identities = {
      too_many = {
        display_name = "over-limit"
        federated_credentials = {
          for i in range(21) : "cred${i}" => {
            display_name = "cred${i}"
            issuer       = "https://app.terraform.io"
            subject      = "organization:o:project:p:workspace:w${i}:run_phase:plan"
          }
        }
      }
    }
  }
  expect_failures = [var.workload_identities]
}
