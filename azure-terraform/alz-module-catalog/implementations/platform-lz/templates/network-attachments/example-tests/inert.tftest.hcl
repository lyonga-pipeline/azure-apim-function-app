mock_provider "azapi" {}
mock_provider "tfe" {}
run "committed_example_is_inert_in_its_own_boundary" {
  command = plan
  assert {
    condition     = !var.enabled && length(var.attachments) == 0 && output.attachments == {} && output.environment == var.environment
    error_message = "Documentation examples must not deploy by default or silently change their boundary label."
  }
}
