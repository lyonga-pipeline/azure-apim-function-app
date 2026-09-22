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

run "normalizes_controlled_and_trims_free_form_values" {
  command = apply

  variables {
    environment           = " PROD "
    application           = " Orders-API "
    appcode               = " ORDERS "
    application_component = " Interest-Calculator "
    owner                 = " Team Alpha "
    source_repo           = " ado://compeer/landing-zone "
    cost_center           = " CC-1000 "
    gl_category           = " 1000015 "
  }

  assert {
    condition = (
      output.tags["environment"] == "prod" &&
      output.tags["application"] == "orders-api" &&
      output.tags["appcode"] == "orders" &&
      output.tags["application_component"] == "interest-calculator" &&
      output.tags["owner"] == "Team Alpha" &&
      output.tags["source_repo"] == "ado://compeer/landing-zone" &&
      output.tags["cost_center"] == "CC-1000" &&
      output.tags["gl_category"] == "1000015"
    )
    error_message = "controlled identifiers must be lowercase and all standard free-form values must be trimmed"
  }
}

run "conditional_and_sandbox_tags" {
  command = apply

  variables {
    environment     = "sandbox"
    application     = "poc-x"
    dr_tier         = "none"
    expiration_date = "2026-12-31"
  }

  assert {
    condition     = output.tags["dr_tier"] == "none" && output.tags["expiration_date"] == "2026-12-31"
    error_message = "conditional + sandbox tags should be emitted when supplied"
  }
}

# ---- created_by: fixed to "Terraform", not caller-overridable --------------

run "created_by_explicit_null_still_defaults_to_terraform" {
  command = apply

  variables {
    created_by = null
  }

  assert {
    condition     = output.tags["created_by"] == "Terraform"
    error_message = "nullable = false must substitute the \"Terraform\" default even when a caller explicitly passes null (e.g. an unset optional object field flowing through as null from a consuming pattern) - this is exactly the bypass the previous plain-default implementation had"
  }
}

run "rejects_non_terraform_created_by" {
  command = plan

  variables {
    created_by = "svc-principal-1234"
  }

  expect_failures = [var.created_by]
}

# ---- additional_tags must not contain a standard tag key -------------------

run "rejects_additional_tags_containing_standard_key" {
  command = plan

  variables {
    application     = "orders"
    additional_tags = { data_classification = "secret" }
  }

  expect_failures = [check.additional_tags_no_standard_key_overlap]
}

run "rejects_additional_tags_overriding_created_by" {
  command = plan

  variables {
    application     = "orders"
    additional_tags = { created_by = "terraform" } # lowercase, the old workaround real tfvars used
  }

  expect_failures = [check.additional_tags_no_standard_key_overlap]
}

run "additional_tags_with_only_organization_specific_keys_still_works" {
  command = apply

  variables {
    application     = "orders"
    additional_tags = { business_unit = "technology", team = "sre" }
  }

  assert {
    condition     = output.tags["business_unit"] == "technology" && output.tags["team"] == "sre"
    error_message = "additional_tags should still work for keys outside the standard schema"
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

run "rejects_impossible_calendar_date" {
  command = plan

  variables {
    created_on = "2026-99-99"
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

# ---- environment vocabulary -------------------------------------------

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "staging"
  }

  expect_failures = [var.environment]
}

run "rejects_poc_as_environment" {
  command = plan

  variables {
    environment = "poc"
  }

  expect_failures = [var.environment]
}

run "accepts_existing_lz_np_environments" {
  command = apply

  variables {
    environment = "np2"
  }

  assert {
    condition     = output.tags["environment"] == "np2" && !contains(keys(output.tags), "expiration_date")
    error_message = "np1/np2/np3 must be accepted as existing-LZ environment aliases without expiration_date"
  }
}

# ---- expiration_date is required and permitted only for sandbox ---------

run "rejects_sandbox_without_expiration_date" {
  command = plan

  variables {
    environment = "sandbox"
  }

  expect_failures = [check.expiration_date_required]
}

run "temporary_lifecycle_without_expiration_date_passes" {
  command = apply

  variables {
    environment     = "prod"
    lifecycle_state = "temporary"
  }

  assert {
    condition     = output.tags["lifecycle_state"] == "temporary" && !contains(keys(output.tags), "expiration_date")
    error_message = "temporary lifecycle outside sandbox must not require expiration_date"
  }
}

run "rejects_expiration_date_for_prod" {
  command = plan

  variables {
    environment     = "prod"
    expiration_date = "2026-12-31"
  }

  expect_failures = [check.expiration_date_only_for_sandbox]
}

run "rejects_time_bound_exception_for_non_exempt_lifecycle" {
  command = plan

  variables {
    environment          = "sandbox"
    lifecycle_state      = "active"
    time_bound_exception = true
    expiration_date      = "2026-12-31"
  }

  expect_failures = [check.time_bound_exception_requires_exempt_lifecycle]
}

run "exempt_non_sandbox_without_time_bound_exception_does_not_require_expiration_date" {
  command = apply

  variables {
    environment     = "prod"
    lifecycle_state = "exempt"
  }

  assert {
    condition     = output.tags["lifecycle_state"] == "exempt" && !contains(keys(output.tags), "expiration_date")
    error_message = "a non-sandbox exemption must not require expiration_date"
  }
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

# ---- date ordering: modified_on / expiration_date vs created_on ------------

run "rejects_modified_on_before_created_on" {
  command = plan

  variables {
    created_on  = "2026-06-01"
    modified_on = "2026-01-01"
  }

  expect_failures = [check.modified_on_not_before_created_on]
}

run "modified_on_on_or_after_created_on_passes" {
  command = apply

  variables {
    created_on  = "2026-06-01"
    modified_on = "2026-06-01"
  }

  assert {
    condition     = output.tags["modified_on"] == "2026-06-01"
    error_message = "modified_on equal to created_on should pass the ordering check"
  }
}

run "rejects_expiration_date_before_created_on" {
  command = plan

  variables {
    environment     = "sandbox"
    created_on      = "2026-06-01"
    expiration_date = "2026-01-01"
  }

  expect_failures = [check.expiration_date_not_before_created_on]
}

run "expiration_date_on_or_after_created_on_passes" {
  command = apply

  variables {
    environment     = "sandbox"
    created_on      = "2026-06-01"
    expiration_date = "2026-06-01"
  }

  assert {
    condition     = output.tags["expiration_date"] == "2026-06-01"
    error_message = "expiration_date equal to created_on should pass the ordering check"
  }
}

# ---- empty supplied mandatory values are rejected, not silently dropped ----

run "rejects_empty_environment" {
  command = plan

  variables {
    environment = ""
  }

  expect_failures = [var.environment]
}

run "rejects_empty_application" {
  command = plan

  variables {
    application = ""
  }

  expect_failures = [var.application]
}

run "rejects_empty_owner" {
  command = plan

  variables {
    owner = ""
  }

  expect_failures = [var.owner]
}

run "rejects_empty_source_repo" {
  command = plan

  variables {
    source_repo = ""
  }

  expect_failures = [var.source_repo]
}

run "rejects_empty_cost_center" {
  command = plan

  variables {
    cost_center = ""
  }

  expect_failures = [var.cost_center]
}

run "rejects_empty_gl_category" {
  command = plan

  variables {
    gl_category = ""
  }

  expect_failures = [var.gl_category]
}

# ---- owner / source_repo structural validation ------------------------

run "rejects_malformed_owner_email" {
  command = plan

  variables {
    owner = "team-alpha@" # has "@" but isn't a well-formed address
  }

  expect_failures = [var.owner]
}

run "accepts_owner_as_distribution_list_email" {
  command = apply

  variables {
    owner = "cloud-platform@compeer.com"
  }

  assert {
    condition     = output.tags["owner"] == "cloud-platform@compeer.com"
    error_message = "a well-formed distribution-list email address must be accepted as owner"
  }
}

run "rejects_malformed_source_repo" {
  command = plan

  variables {
    source_repo = "just-a-plain-string-with-no-scheme"
  }

  expect_failures = [var.source_repo]
}

run "accepts_source_repo_with_scheme" {
  command = apply

  variables {
    source_repo = "https://github.com/Compeer/landing-zone"
  }

  assert {
    condition     = output.tags["source_repo"] == "https://github.com/Compeer/landing-zone"
    error_message = "a URI with a scheme must be accepted as source_repo"
  }
}

run "rejects_empty_application_component_when_supplied" {
  command = plan

  variables {
    application_component = ""
  }

  expect_failures = [var.application_component]
}

# ---- mandatory_keys / missing_mandatory never error, even with every -----
# ---- mandatory variable left at its null default -------------------------

run "all_mandatory_tags_unset_does_not_error" {
  command = apply

  assert {
    condition     = contains(output.mandatory_keys, "created_by") && !contains(output.missing_mandatory, "created_by")
    error_message = "created_by must be part of the mandatory schema and automatically satisfied by its Terraform default"
  }
  assert {
    condition     = length(output.missing_mandatory) == length(output.mandatory_keys) - 1
    error_message = "every unset mandatory business tag should be reported while the mandatory created_by tag remains automatically satisfied"
  }
  assert {
    condition     = length(output.tags) == 1 && output.tags["created_by"] == "Terraform"
    error_message = "with literally nothing supplied, only the created_by default should be emitted - the module must not error"
  }
}
