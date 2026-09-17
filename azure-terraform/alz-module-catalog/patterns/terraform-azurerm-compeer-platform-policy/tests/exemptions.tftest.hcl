mock_provider "azurerm" {}

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  management_group_ids = {
    compeer-enterprise-mg = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg"
  }
}

run "exemption_resolves_management_group_key" {
  command = plan

  variables {
    policy_exemptions = {
      waiver = {
        scope_type           = "management_group"
        management_group_key = "compeer-enterprise-mg"
        policy_assignment_id = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg/providers/Microsoft.Authorization/policyAssignments/existing"
      }
    }
  }

  assert {
    condition     = local.policy_exemptions_input["waiver"].management_group_id == "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg"
    error_message = "management_group_key should resolve to a concrete management_group_id before reaching module.policy"
  }
}

# policy_assignment_key resolves against module.policy's OWN merged
# assignment map at apply-time (it points at a sibling assignment the module
# itself creates); at plan time we can only prove the input was wired
# through unresolved, since the referenced assignment's ID isn't known yet.
run "exemption_by_assignment_key_is_passed_through" {
  command = plan

  variables {
    management_group_policy_assignments = {
      guardrail = {
        management_group_key = "compeer-enterprise-mg"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000"
      }
    }
    policy_exemptions = {
      waiver = {
        scope_type            = "management_group"
        management_group_key  = "compeer-enterprise-mg"
        policy_assignment_key = "guardrail"
      }
    }
  }

  assert {
    condition     = local.policy_exemptions_input["waiver"].policy_assignment_key == "guardrail"
    error_message = "policy_assignment_key should pass through unresolved for module.policy to resolve internally"
  }
}
