check "expiration_date_required" {
  assert {
    condition     = lower(trimspace(coalesce(var.environment, "__unset__"))) != "sandbox" || var.expiration_date != null
    error_message = "expiration_date is required when environment is \"sandbox\"."
  }
}

check "expiration_date_only_for_sandbox" {
  assert {
    condition     = var.expiration_date == null || lower(trimspace(coalesce(var.environment, "__unset__"))) == "sandbox"
    error_message = "expiration_date may only be set when environment is \"sandbox\"."
  }
}

check "time_bound_exception_requires_exempt_lifecycle" {
  assert {
    condition     = !var.time_bound_exception || (var.lifecycle_state == "exempt" && lower(trimspace(coalesce(var.environment, "__unset__"))) == "sandbox")
    error_message = "time_bound_exception may only be true for a sandbox resource whose lifecycle_state is \"exempt\"."
  }
}

check "additional_tags_no_standard_key_overlap" {
  assert {
    condition     = length(setintersection(keys(var.additional_tags), keys(local.candidate))) == 0
    error_message = "additional_tags must not contain any standard tag key: ${jsonencode(sort(setintersection(keys(var.additional_tags), keys(local.candidate))))}. Use each standard tag's own dedicated variable instead - additional_tags is only for organization-specific metadata outside this module's standard schema."
  }
}

check "modified_on_not_before_created_on" {
  assert {
    condition     = !try(timecmp("${var.modified_on}T00:00:00Z", "${var.created_on}T00:00:00Z") < 0, false)
    error_message = "modified_on (${coalesce(var.modified_on, "unset")}) must not be before created_on (${coalesce(var.created_on, "unset")})."
  }
}

check "expiration_date_not_before_created_on" {
  assert {
    condition     = !try(timecmp("${var.expiration_date}T00:00:00Z", "${var.created_on}T00:00:00Z") < 0, false)
    error_message = "expiration_date (${coalesce(var.expiration_date, "unset")}) must not be before created_on (${coalesce(var.created_on, "unset")})."
  }
}
