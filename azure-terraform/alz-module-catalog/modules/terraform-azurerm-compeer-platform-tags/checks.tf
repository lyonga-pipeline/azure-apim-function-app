# =============================================================================
# Cross-variable checks a single variable's own `validation` block can't
# express (a validation block can only see the variable it's declared on in
# Terraform versions before 1.9, and this module supports 1.5+ - same reason
# the naming module uses `check` blocks for its own cross-input rules).
# =============================================================================

check "expiration_date_required" {
  assert {
    # Design-doc Table 4: "expiration_date - Required for sandbox, POC,
    # temporary, and exception resources." Expressed as: expiration_date is
    # required when
    #   - environment is outside the four standard, durable environments
    #     (dev/test/uat/prod) - which today means sandbox or poc, and
    #     automatically covers any future environment value this module's
    #     own vocabulary is extended to include, without this check needing
    #     a matching update, OR
    #   - lifecycle_state is "temporary" (intentionally short-lived), OR
    #   - time_bound_exception is true (an approved lifecycle_state =
    #     "exempt" resource whose exception was specifically approved with
    #     a planned end date - a permanent exemption does NOT set this and
    #     is correctly not required to have one).
    #
    # coalesce(var.environment, "prod") is a null-safety guard, not a real
    # fallback: `&&`/`||` do NOT short-circuit function evaluation in HCL
    # (only the boolean result), so lower(var.environment) still gets
    # evaluated - and crashes - even when var.environment is null and every
    # other operand already makes this specific OR-branch irrelevant. When
    # environment actually is null this substitutes "prod" purely so
    # lower() doesn't error; that branch's contribution is then "prod" is a
    # standard environment, i.e. false, exactly as if environment had never
    # been set.
    condition = !(
      var.expiration_date == null &&
      (
        !contains(["dev", "test", "uat", "prod"], lower(trimspace(coalesce(var.environment, "prod")))) ||
        var.lifecycle_state == "temporary" ||
        var.time_bound_exception == true
      )
    )
    error_message = "expiration_date is required when environment is sandbox/poc (or any value outside dev/test/uat/prod), lifecycle_state is \"temporary\", or time_bound_exception is true - sandbox, POC, temporary, and time-bound exception resources must have a planned end date (design doc: \"Required for sandbox, POC, temporary, and exception resources\")."
  }
}

check "time_bound_exception_requires_exempt_lifecycle" {
  assert {
    condition     = !var.time_bound_exception || var.lifecycle_state == "exempt"
    error_message = "time_bound_exception may only be true when lifecycle_state is \"exempt\". Use lifecycle_state = \"temporary\" for ordinary short-lived resources."
  }
}

check "additional_tags_no_standard_key_overlap" {
  assert {
    # additional_tags exists to extend the schema with organization-specific
    # metadata, not to override OR populate a standard tag - either would let
    # a caller bypass that standard tag's own first-class validation (e.g.
    # additional_tags = { data_classification = "secret" } never goes
    # through data_classification's own contains() check). Checked against
    # every standard key name (local.candidate, from main.tf) regardless of
    # whether that key's own variable is currently set, since the whole
    # point is to block the key from entering through the side door at all.
    condition     = length(setintersection(keys(var.additional_tags), keys(local.candidate))) == 0
    error_message = "additional_tags must not contain any standard tag key: ${jsonencode(sort(setintersection(keys(var.additional_tags), keys(local.candidate))))}. Use each standard tag's own dedicated variable instead - additional_tags is only for organization-specific metadata outside this module's standard schema."
  }
}

check "modified_on_not_before_created_on" {
  assert {
    # try(..., false) - not just can() as a preceding guard - because `&&`
    # does not short-circuit function evaluation in HCL: even gating this
    # exact timecmp() call behind `can(that same call)` still evaluates the
    # ungated copy on the right of `&&` and crashes on a null/malformed
    # interpolation. try() wraps the actual value-producing expression
    # itself, so a malformed or absent date - which already gets its own
    # clear error from modified_on's or created_on's own validation block -
    # just resolves this comparison to "not a violation" instead.
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
