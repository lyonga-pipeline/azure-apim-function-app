# Proves the "created_on must be stable, not recomputed every plan" claim
# empirically instead of just documenting it: apply once, then plan again
# with no config changes and confirm the SAME created_on value comes back.
# time_static computes its value once on first apply and Terraform reads it
# straight from state on every later plan - a raw timestamp() call would not
# offer this guarantee (each plan re-evaluates it, risking a different value
# and a perpetual diff on every subsequent run).

run "first_apply_creates_deployment_created" {
  command = apply

  assert {
    condition     = output.tags["created_on"] != null
    error_message = "created_on must be present in the emitted tag map after the first apply"
  }
}

run "second_plan_reuses_the_same_created_on" {
  command = plan

  assert {
    condition     = output.tags["created_on"] == run.first_apply_creates_deployment_created.tags["created_on"]
    error_message = "created_on must be stable across a subsequent plan with no config changes - time_static computes it once on first apply and Terraform reads it back from state on every later plan, unlike timestamp() which would recompute (and could produce a different value, and therefore a diff) on every single plan"
  }
}
