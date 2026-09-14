# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azurerm_pim_eligible_role_assignment.this
  to   = azurerm_pim_eligible_role_assignment.eligible_assignment
}
