mock_provider "azurerm" {}
run "empty_inputs_preserve_existing_platform" {
  command = plan
  assert {
    condition     = length(module.phase2.export_ids) == 0
    error_message = "No Phase 2 resources without explicit capability inputs."
  }
}
