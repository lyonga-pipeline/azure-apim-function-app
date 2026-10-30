mock_provider "tfe" {
  mock_data "tfe_workspace" {
    defaults = {
      id                        = "ws-1234567890ABCDEF"
      execution_mode            = "agent"
      auto_apply                = false
      global_remote_state       = false
      project_remote_state      = false
      remote_state_consumer_ids = []
    }
  }
}
run "enabled_drift_example_is_fully_wired" {
  command = plan
  assert {
    condition     = length(module.phase2.settings_ids) == 1
    error_message = "Health assessments must forward approved existing workspace settings without adding Phase 3 RBAC or vending."
  }
}
