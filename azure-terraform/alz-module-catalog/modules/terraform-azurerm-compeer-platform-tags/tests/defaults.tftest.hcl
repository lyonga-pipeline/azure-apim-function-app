run "emits_only_supplied_tags" {
  command = apply

  variables {
    environment         = "prod"
    application         = "orders"
    appcode             = "orders"
    owner               = "team-alpha"
    source_repo         = "ado://compeer/landing-zone"
    created_on          = "2026-09-02"
    criticality_tier    = "tier-1"
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
    condition     = output.tags["created_by"] == "Terraform"
    error_message = "created_by should default to \"Terraform\" even when not supplied - it's the deployment mechanism for every resource this module tags"
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
    environment = "dev"
    application = "poc-x"
  }

  assert {
    condition     = contains(output.missing_mandatory, "owner") && contains(output.missing_mandatory, "cost_center") && contains(output.missing_mandatory, "gl_category") && contains(output.missing_mandatory, "appcode")
    error_message = "missing_mandatory should list the unsupplied Required=Yes tags, including the new appcode tag"
  }
  assert {
    condition     = length(output.tags) == 3
    error_message = "only environment + application + the created_by default should be emitted"
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
    error_message = "an explicit created_by should override the \"Terraform\" default, and conditional + sandbox tags should be emitted when supplied"
  }
}

run "additional_tags_fill_standard_keys" {
  command = apply

  variables {
    application     = "orders"
    additional_tags = { environment = "dev", owner = "team-alpha", team = "sre" }
  }

  assert {
    condition     = output.tags["environment"] == "dev" && output.tags["owner"] == "team-alpha" && output.tags["team"] == "sre"
    error_message = "additional_tags should fill standard keys when first-class inputs are not supplied"
  }
}

run "standard_tags_win_on_collision" {
  command = apply

  variables {
    environment     = "prod"
    application     = "orders"
    additional_tags = { environment = "override", team = "sre" }
  }

  assert {
    condition     = output.tags["environment"] == "prod" && output.tags["team"] == "sre"
    error_message = "first-class standard tag inputs should win over additional_tags on collision"
  }
}

run "additional_tags_created_by_is_overridden_by_the_default" {
  command = apply

  variables {
    environment     = "prod"
    application     = "orders"
    additional_tags = { created_by = "terraform" } # lowercase, the old workaround real tfvars used
  }

  assert {
    condition     = output.tags["created_by"] == "Terraform"
    error_message = "the module's own created_by default (\"Terraform\") must win over an additional_tags workaround value, the same as any other standard tag collision"
  }
}

run "rejects_bad_classification" {
  command = plan

  variables {
    data_classification = "secret"
  }

  expect_failures = [var.data_classification]
}

run "rejects_bad_date_format" {
  command = plan

  variables {
    created_on = "09/02/2026"
  }

  expect_failures = [var.created_on]
}

# ---- New: appcode ------------------------------------------------------

run "rejects_appcode_over_9_letters" {
  command = plan

  variables {
    appcode = "verylongapplicationcode"
  }

  expect_failures = [var.appcode]
}

run "rejects_appcode_with_non_letter_characters" {
  command = plan

  variables {
    appcode = "app-01"
  }

  expect_failures = [var.appcode]
}

run "accepts_valid_appcode" {
  command = apply

  variables {
    appcode = "orders"
  }

  assert {
    condition     = output.tags["appcode"] == "orders"
    error_message = "a valid 1-9 letter appcode should be emitted verbatim"
  }
}

# ---- New: criticality_tier ----------------------------------------------

run "rejects_bad_criticality_tier" {
  command = plan

  variables {
    criticality_tier = "tier1" # missing the hyphen the design doc uses
  }

  expect_failures = [var.criticality_tier]
}

run "accepts_tier_0_through_tier_4" {
  command = apply

  variables {
    criticality_tier = "tier-0"
  }

  assert {
    condition     = output.tags["criticality_tier"] == "tier-0"
    error_message = "tier-0 (foundational platform service) must be a valid criticality_tier"
  }
}

# ---- New: lifecycle_state ------------------------------------------------

run "rejects_bad_lifecycle_state" {
  command = plan

  variables {
    lifecycle_state = "deprecated" # not one of the design doc's six values
  }

  expect_failures = [var.lifecycle_state]
}

run "accepts_all_lifecycle_states" {
  command = apply

  variables {
    lifecycle_state = "decommission-pending"
  }

  assert {
    condition     = output.tags["lifecycle_state"] == "decommission-pending"
    error_message = "decommission-pending must be a valid lifecycle_state"
  }
}

# ---- New: dr_tier ----------------------------------------------------------

run "rejects_bad_dr_tier" {
  command = plan

  variables {
    dr_tier = "platinum"
  }

  expect_failures = [var.dr_tier]
}

run "accepts_all_dr_tiers" {
  command = apply

  variables {
    dr_tier = "silver"
  }

  assert {
    condition     = output.tags["dr_tier"] == "silver"
    error_message = "silver must be a valid dr_tier"
  }
}

# ---- New: expiration_date required for sandbox / non-standard environment -

run "rejects_sandbox_without_expiration_date" {
  command = plan

  variables {
    environment = "sandbox"
  }

  expect_failures = [check.expiration_date_required_for_sandbox_or_nonstandard_environment]
}

run "rejects_nonstandard_environment_without_expiration_date" {
  command = plan

  variables {
    environment = "poc"
  }

  expect_failures = [check.expiration_date_required_for_sandbox_or_nonstandard_environment]
}

run "sandbox_with_expiration_date_passes" {
  command = apply

  variables {
    environment     = "sandbox"
    expiration_date = "2026-12-31"
  }

  assert {
    condition     = output.tags["expiration_date"] == "2026-12-31"
    error_message = "sandbox with an explicit expiration_date should pass the cross-variable check"
  }
}

run "standard_environments_do_not_require_expiration_date" {
  command = apply

  variables {
    environment = "prod"
  }

  assert {
    condition     = !contains(keys(output.tags), "expiration_date")
    error_message = "dev/test/uat/prod should not require expiration_date"
  }
}

# ---- mandatory_keys / missing_mandatory never error, even with every -----
# ---- mandatory variable left at its null default -------------------------

run "all_mandatory_tags_unset_does_not_error" {
  command = apply

  assert {
    condition     = length(output.missing_mandatory) == length(output.mandatory_keys)
    error_message = "missing_mandatory should report every mandatory key when nothing is supplied (created_by is Conditional, not in mandatory_keys, so it doesn't affect this count) - and, critically, this must not error just because every mandatory variable defaults to null"
  }
  assert {
    condition     = length(output.tags) == 1 && output.tags["created_by"] == "Terraform"
    error_message = "with literally nothing supplied, only the created_by default should be emitted - the module must not error"
  }
}
