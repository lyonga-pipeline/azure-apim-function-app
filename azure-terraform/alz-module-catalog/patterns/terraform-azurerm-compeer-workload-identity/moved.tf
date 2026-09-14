# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = azuread_application_federated_identity_credential.this
  to   = azuread_application_federated_identity_credential.federated_credential
}

moved {
  from = azurerm_role_assignment.this
  to   = azurerm_role_assignment.assignment
}
