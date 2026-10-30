mock_provider "azurerm" {}
run "enabled_services_example_is_fully_wired" {
  command = plan
  assert {
    condition     = length(module.phase2.gallery_ids) == 1 && length(module.phase2.maintenance_assignment_ids) == 1
    error_message = "The published gallery and approved patch assignment must compose through the deployment root."
  }
}
