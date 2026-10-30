mock_provider "azurerm" {}
run "enabled_archive_example_is_fully_wired" {
  command = plan
  assert {
    condition     = length(module.phase2.export_ids) == 1
    error_message = "The published archive pilot must wire actual export, not just a storage account."
  }
}
