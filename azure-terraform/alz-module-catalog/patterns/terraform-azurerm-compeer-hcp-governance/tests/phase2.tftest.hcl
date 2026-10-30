mock_provider "tfe" {
  mock_data "tfe_workspace" {
    defaults = {
      id                        = "ws-1234567890ABCDEF"
      execution_mode            = "agent"
      auto_apply                = true
      global_remote_state       = false
      project_remote_state      = false
      remote_state_consumer_ids = ["ws-ABCDEF1234567890"]
    }
  }
}
variables { organization = "example-org" }
run "defaults_do_not_adopt_workspaces" {
  command = plan
  assert {
    condition     = length(tfe_workspace_settings.assessments) == 0 && length(data.tfe_workspace.existing) == 0
    error_message = "No HCP changes or API reads without explicit ownership."
  }
}
run "assessments_preserve_existing_apply_and_sharing_settings" {
  command = plan
  variables {
    workspace_settings = { policy = {
      workspace_id  = "ws-1234567890ABCDEF", workspace_name = "platform-policy", execution_mode = "agent",
      agent_pool_id = "apool-1234567890ABCDEF", ownership_approved = true
    } }
  }
  assert {
    condition = (tfe_workspace_settings.assessments["policy"].assessments_enabled &&
      tfe_workspace_settings.assessments["policy"].auto_apply &&
      tfe_workspace_settings.assessments["policy"].execution_mode == "agent" &&
    tfe_workspace_settings.assessments["policy"].remote_state_consumer_ids == toset(["ws-ABCDEF1234567890"]))
    error_message = "Only health assessment intent may change; preserve existing apply approval and state consumers."
  }
}
run "wrong_workspace_context_is_rejected" {
  command = plan
  variables {
    workspace_settings = { policy = {
      workspace_id  = "ws-ABCDEF1234567890", workspace_name = "platform-policy", execution_mode = "agent",
      agent_pool_id = "apool-1234567890ABCDEF", ownership_approved = true
    } }
  }
  expect_failures = [tfe_workspace_settings.assessments]
}
run "drift_enablement_cannot_replace_state_consumers" {
  command = plan
  variables {
    workspace_settings = { policy = {
      workspace_id  = "ws-1234567890ABCDEF", workspace_name = "platform-policy", execution_mode = "agent",
      agent_pool_id = "apool-1234567890ABCDEF", ownership_approved = true, remote_state_consumer_ids = []
    } }
  }
  expect_failures = [tfe_workspace_settings.assessments]
}
