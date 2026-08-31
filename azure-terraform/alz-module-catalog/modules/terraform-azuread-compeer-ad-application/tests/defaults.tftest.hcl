mock_provider "azuread" {}

variables {
  display_name = "app-platform-test"
}

run "minimal" {
  command = apply

  assert {
    condition     = azuread_application.ad_application.display_name == "app-platform-test"
    error_message = "display_name not wired"
  }
  assert {
    condition     = length(azuread_application.ad_application.app_role) == 0
    error_message = "no app roles by default"
  }
  assert {
    condition     = length(azuread_application.ad_application.web) == 0
    error_message = "no web block by default"
  }
}

run "app_roles_keyed" {
  command = apply

  variables {
    app_role = {
      admin = {
        id                   = "00000000-0000-0000-0000-000000000001"
        allowed_member_types = ["User"]
        description          = "Administrators"
        display_name         = "Admin"
        value                = "Admin"
      }
    }
    web = {
      redirect_uris  = ["https://app.example.com/callback"]
      implicit_grant = { id_token_issuance_enabled = true }
    }
  }

  assert {
    condition     = length(azuread_application.ad_application.app_role) == 1
    error_message = "expected one app role"
  }
  assert {
    condition     = length(azuread_application.ad_application.web) == 1
    error_message = "web block should render"
  }
}

run "rejects_bad_sign_in_audience" {
  command = plan
  variables { sign_in_audience = "Everyone" }
  expect_failures = [var.sign_in_audience]
}

run "rejects_bad_member_type" {
  command = plan
  variables {
    app_role = {
      x = { id = "00000000-0000-0000-0000-000000000002", allowed_member_types = ["Robot"], description = "d", display_name = "X" }
    }
  }
  expect_failures = [var.app_role]
}
