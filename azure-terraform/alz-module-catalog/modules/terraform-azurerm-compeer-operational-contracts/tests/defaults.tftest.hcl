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

run "rejects_unknown_state" {
  command = plan
  variables {
    contracts = { x = { implementation_state = "someday" } }
  }
  expect_failures = [var.contracts]
}

run "classifies_by_state" {
  command = apply
  variables {
    contracts = {
      break_glass        = { implementation_state = "manual-control" }
      conditional_access = { implementation_state = "external-system" }
      rbac_groups        = { implementation_state = "codified" }
      pim_policy         = { implementation_state = "provider-gap" }
    }
  }
  assert {
    condition     = length(output.codified_keys) == 1 && output.codified_keys[0] == "rbac_groups"
    error_message = "codified_keys should list only codified contracts"
  }
  assert {
    condition     = length(output.manual_control_keys) == 3
    error_message = "manual_control_keys should list every non-codified contract"
  }
  assert {
    condition     = length(output.keys_by_state["manual-control"]) == 1 && output.keys_by_state["manual-control"][0] == "break_glass"
    error_message = "keys_by_state should bucket by implementation_state"
  }
}
