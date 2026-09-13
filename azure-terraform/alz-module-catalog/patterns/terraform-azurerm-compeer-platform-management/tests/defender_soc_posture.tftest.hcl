mock_provider "azurerm" {}

# Exercises terraform_data.defender_soc_posture_contract - the precondition
# that stops the pattern from claiming a Defender/Sentinel/security-contact
# posture is "enabled" when the underlying resources aren't actually
# configured (design doc Phase 6 core Defender plans / security contact).
# Had zero test coverage before this file.

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  location        = "centralus"
  environment     = "prod"
  resource_group  = { name = "rg-mgmt" }
  log_analytics   = { name = "law-platform" }
  action_group    = { short_name = "mgmt" }
}

run "posture_off_by_default_is_a_noop" {
  command = plan
  assert {
    condition     = terraform_data.defender_soc_posture_contract.input.enabled == false
    error_message = "defender/SOC posture should be inert by default"
  }
}

run "rejects_defender_standard_claim_without_plans" {
  command = plan
  variables {
    defender_soc_posture = {
      enabled                   = true
      defender_standard_enabled = true
    }
    defender_plans = {}
  }
  expect_failures = [terraform_data.defender_soc_posture_contract]
}

run "defender_standard_claim_with_plans_passes" {
  command = plan
  variables {
    defender_soc_posture = {
      enabled                   = true
      defender_standard_enabled = true
    }
    defender_plans = {
      servers = { resource_type = "VirtualMachines", tier = "Standard" }
    }
  }
  assert {
    condition     = terraform_data.defender_soc_posture_contract.input.defender_plan_count == 1
    error_message = "expected the defender plan count to be recorded"
  }
}

run "rejects_security_contact_claim_without_contact" {
  command = plan
  variables {
    defender_soc_posture = {
      enabled                  = true
      security_contact_enabled = true
    }
    security_contact = null
  }
  expect_failures = [terraform_data.defender_soc_posture_contract]
}

run "security_contact_claim_with_contact_passes" {
  command = plan
  variables {
    defender_soc_posture = {
      enabled                  = true
      security_contact_enabled = true
    }
    security_contact = { email = "cloudsecurity@compeer.example" }
  }
  assert {
    condition     = terraform_data.defender_soc_posture_contract.input.security_contact_configured == true
    error_message = "expected the security contact to be recorded as configured"
  }
}
