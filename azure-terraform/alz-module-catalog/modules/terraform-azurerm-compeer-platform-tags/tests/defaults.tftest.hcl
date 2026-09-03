run "emits_only_supplied_tags" {
  command = apply

  variables {
    environment         = "prod"
    application         = "orders"
    owner               = "team-alpha"
    source_repo         = "ado://compeer/landing-zone"
    created_on          = "2026-09-02"
    criticality_tier    = "tier1"
    data_classification = "confidential"
    lifecycle_state     = "active"
    cost_center         = "CC-1000"
    gl_category         = "opex-cloud"
  }

  assert {
    condition     = output.tags["environment"] == "prod" && output.tags["owner"] == "team-alpha" && output.tags["gl_category"] == "opex-cloud"
    error_message = "supplied mandatory tags should be emitted verbatim"
  }
  assert {
    condition     = !contains(keys(output.tags), "dr_tier") && !contains(keys(output.tags), "application_component") && !contains(keys(output.tags), "expiration_date")
    error_message = "unset optional/conditional tags must be dropped, not emitted empty"
  }
  assert {
    condition     = length(output.missing_mandatory) == 0
    error_message = "all mandatory tags were supplied"
  }
}

run "reports_missing_mandatory" {
  command = apply

  variables {
    environment = "sandbox"
    application = "poc-x"
  }

  assert {
    condition     = contains(output.missing_mandatory, "owner") && contains(output.missing_mandatory, "cost_center") && contains(output.missing_mandatory, "gl_category")
    error_message = "missing_mandatory should list the unsupplied Required=Yes tags"
  }
  assert {
    condition     = length(output.tags) == 2
    error_message = "only environment + application should be emitted"
  }
}

run "conditional_and_sandbox_tags" {
  command = apply

  variables {
    environment     = "sandbox"
    application     = "poc-x"
    created_by      = "chrls@example"
    dr_tier         = "none"
    expiration_date = "2026-12-31"
  }

  assert {
    condition     = output.tags["created_by"] == "chrls@example" && output.tags["dr_tier"] == "none" && output.tags["expiration_date"] == "2026-12-31"
    error_message = "conditional + sandbox tags emitted when supplied"
  }
}

run "additional_tags_win" {
  command = apply

  variables {
    environment     = "prod"
    application     = "orders"
    additional_tags = { environment = "override", team = "sre" }
  }

  assert {
    condition     = output.tags["environment"] == "override" && output.tags["team"] == "sre"
    error_message = "additional_tags merged last and win on collision"
  }
}

run "rejects_bad_classification" {
  command = plan

  variables {
    data_classification = "secret"
  }

  expect_failures = [var.data_classification]
}
