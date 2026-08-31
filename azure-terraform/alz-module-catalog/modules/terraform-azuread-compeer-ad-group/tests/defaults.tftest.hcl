mock_provider "azuread" {}

variables {
  display_name = "sg-platform-admins"
}

run "security_group_default" {
  command = apply
  assert {
    condition     = azuread_group.ad_group.security_enabled == true
    error_message = "security_enabled should default true"
  }
  assert {
    condition     = length(azuread_group.ad_group.dynamic_membership) == 0
    error_message = "no dynamic membership block by default"
  }
}

run "dynamic_membership" {
  command = apply
  variables {
    dynamic_membership = { enabled = true, rule = "user.department -eq \"IT\"" }
  }
  assert {
    condition     = length(azuread_group.ad_group.dynamic_membership) == 1
    error_message = "dynamic_membership block should render"
  }
}

run "rejects_bad_visibility" {
  command = plan
  variables { visibility = "Everyone" }
  expect_failures = [var.visibility]
}
