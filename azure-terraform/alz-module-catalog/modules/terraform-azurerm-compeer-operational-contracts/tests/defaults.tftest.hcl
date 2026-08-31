run "tracks_contracts" {
  command = apply
  variables {
    contracts = {
      ddos = { phase = "Phase 2", implementation_state = "contract-only", enabled = false }
    }
  }
  assert {
    condition     = length(terraform_data.contract) == 1
    error_message = "expected one tracked contract"
  }
}
run "rejects_enabled_contract_only" {
  command = plan
  variables {
    contracts = { x = { enabled = true, implementation_state = "contract-only" } }
  }
  expect_failures = [terraform_data.contract]
}
