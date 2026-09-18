# =============================================================================
# Cross-variable checks a single variable's own `validation` block can't
# express (a validation block can only see the variable it's declared on in
# Terraform versions before 1.9, and this module supports 1.5+ - same reason
# the naming module uses `check` blocks for its own cross-input rules).
# =============================================================================

check "expiration_date_required_for_sandbox_or_nonstandard_environment" {
  assert {
    # Design-doc Table 4: "expiration_date - Required for sandbox, POC,
    # temporary, and exception resources." environment = "sandbox" is the
    # explicit case; anything else outside the four standard, durable
    # environments (dev/test/uat/prod) is treated the same way, since it's
    # by definition non-standard.
    #
    # coalesce(var.environment, "prod") is a null-safety guard, not a real
    # fallback: `&&` does NOT short-circuit function evaluation in HCL (only
    # the boolean result), so lower(var.environment) still gets evaluated -
    # and crashes - even when the earlier `var.environment != null` clause
    # already made the whole condition false. When environment actually is
    # null this substitutes "prod" purely so lower() doesn't error; the
    # outer `var.environment != null` clause guarantees that branch's value
    # is discarded either way.
    condition = !(
      var.environment != null &&
      var.expiration_date == null &&
      (
        lower(coalesce(var.environment, "prod")) == "sandbox" ||
        !contains(["dev", "test", "uat", "prod"], lower(coalesce(var.environment, "prod")))
      )
    )
    error_message = "expiration_date is required when environment is \"sandbox\" or any value other than dev/test/uat/prod - temporary, POC, and exception resources must have a planned end date (design doc: \"Required for sandbox, POC, temporary, and exception resources\")."
  }
}
