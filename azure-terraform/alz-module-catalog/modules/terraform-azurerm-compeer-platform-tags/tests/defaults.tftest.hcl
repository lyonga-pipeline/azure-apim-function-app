run "normalized_tag_map" {
  command = apply

  variables {
    environment    = "prod"
    application    = "orders"
    business_owner = "team-alpha"
  }

  assert {
    condition     = output.tags["env"] == "prod"
    error_message = "env key should carry the environment value"
  }
  assert {
    condition     = !contains(keys(output.tags), "recovery")
    error_message = "null recovery_tier should be dropped from the map"
  }
  assert {
    condition     = output.tags["bt_owner"] == "team-alpha"
    error_message = "business_owner maps to bt_owner"
  }
}

run "rejects_bad_environment" {
  command = plan
  variables {
    environment = "dev"
    application = "x"
  }
  expect_failures = [var.environment]
}

run "rejects_bad_classification" {
  command = plan
  variables {
    environment         = "prod"
    application         = "x"
    data_classification = "secret"
  }
  expect_failures = [var.data_classification]
}
