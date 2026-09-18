mock_provider "azurerm" {}

run "empty_is_noop" {
  command = plan
  assert {
    condition     = length(azurerm_policy_definition.definition) == 0 && length(azurerm_management_group_policy_set_definition.initiative) == 0
    error_message = "nothing managed by default"
  }
}

# command = plan, not apply: the reference's policy_definition_id resolves to
# a sibling azurerm_policy_definition's .id, which mock_provider fills with a
# non-Azure-ID-shaped value - that only fails the resource's own ID-format
# validation at apply, not at plan (see the exemption_by_assignment_key run
# below for the same reasoning). Count/key assertions are all plan can prove
# here; the actual cross-reference wiring is exercised for real in the two
# patterns that call this module.
run "definitions_and_initiative_reference_by_key" {
  command = plan

  variables {
    policy_definitions = {
      deny-a = {
        display_name        = "Deny A"
        management_group_id = "/providers/Microsoft.Management/managementGroups/corp"
        policy_rule         = { if = { field = "type", equals = "A" }, then = { effect = "Deny" } }
      }
      deny-b = {
        display_name        = "Deny B"
        management_group_id = "/providers/Microsoft.Management/managementGroups/corp"
        policy_rule         = { if = { field = "type", equals = "B" }, then = { effect = "Deny" } }
      }
    }
    policy_set_definitions = {
      bundle = {
        display_name        = "Bundle"
        management_group_id = "/providers/Microsoft.Management/managementGroups/corp"
        policy_definition_references = [
          { policy_definition_key = "deny-a", reference_id = "a" },
          { policy_definition_key = "deny-b", reference_id = "b" },
        ]
      }
    }
  }

  assert {
    condition     = length(azurerm_policy_definition.definition) == 2
    error_message = "expected both custom definitions to be created"
  }
  assert {
    condition     = length(azurerm_management_group_policy_set_definition.initiative["bundle"].policy_definition_reference) == 2
    error_message = "expected the initiative to reference both sibling definitions"
  }
}

run "mg_assignment_with_identity_not_scopes_and_message" {
  command = plan

  variables {
    management_group_assignments = {
      guardrail = {
        management_group_id  = "/providers/Microsoft.Management/managementGroups/corp"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000"
        enforce              = false
        not_scopes           = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/exempt-rg"]
        identity             = { type = "SystemAssigned" }
        non_compliance_messages = {
          default = { content = "Not compliant." }
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_management_group_policy_assignment.mg_assignment) == 1
    error_message = "expected the assignment to be created"
  }
  assert {
    condition     = azurerm_management_group_policy_assignment.mg_assignment["guardrail"].enforce == false
    error_message = "enforce flag should pass through"
  }
  assert {
    condition     = azurerm_management_group_policy_assignment.mg_assignment["guardrail"].not_scopes == tolist(["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/exempt-rg"])
    error_message = "not_scopes should pass through"
  }
  assert {
    condition     = length(azurerm_management_group_policy_assignment.mg_assignment["guardrail"].identity) == 1
    error_message = "identity block should be present"
  }
  assert {
    condition     = azurerm_management_group_policy_assignment.mg_assignment["guardrail"].non_compliance_message[0].content == "Not compliant."
    error_message = "non_compliance_message content should pass through"
  }
}

run "subscription_and_resource_group_assignments" {
  command = plan

  variables {
    subscription_assignments = {
      sub_guardrail = {
        subscription_id      = "/subscriptions/00000000-0000-0000-0000-000000000000"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000"
      }
    }
    resource_group_assignments = {
      rg_guardrail = {
        resource_group_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000"
      }
    }
  }

  assert {
    condition     = length(azurerm_subscription_policy_assignment.subscription_assignment) == 1
    error_message = "expected the subscription assignment to be created"
  }
  assert {
    condition     = length(azurerm_resource_group_policy_assignment.rg_assignment) == 1
    error_message = "expected the resource group assignment to be created"
  }
}

run "exemption_by_direct_assignment_id" {
  command = plan

  variables {
    exemptions = {
      waiver = {
        scope_type           = "management_group"
        management_group_id  = "/providers/Microsoft.Management/managementGroups/corp"
        policy_assignment_id = "/providers/Microsoft.Management/managementGroups/corp/providers/Microsoft.Authorization/policyAssignments/existing"
        expires_on           = "2027-01-01T00:00:00Z"
      }
    }
  }

  assert {
    condition     = length(azurerm_management_group_policy_exemption.mg_exemption) == 1
    error_message = "expected the exemption to be created"
  }
}

run "exemption_by_assignment_key" {
  command = plan

  variables {
    subscription_assignments = {
      sub_guardrail = {
        subscription_id      = "/subscriptions/00000000-0000-0000-0000-000000000000"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000"
      }
    }
    exemptions = {
      waiver = {
        scope_type            = "subscription"
        subscription_id       = "/subscriptions/00000000-0000-0000-0000-000000000000"
        policy_assignment_key = "sub_guardrail"
      }
    }
  }

  assert {
    condition     = length(azurerm_subscription_policy_exemption.subscription_exemption) == 1
    error_message = "expected the exemption to be created against the same-call assignment"
  }
}

run "rejects_assignment_with_two_definition_refs" {
  command = plan

  variables {
    management_group_assignments = {
      bad = {
        management_group_id      = "/providers/Microsoft.Management/managementGroups/corp"
        policy_definition_id     = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000"
        policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/00000000-0000-0000-0000-000000000000"
      }
    }
  }

  expect_failures = [var.management_group_assignments]
}

run "rejects_exemption_missing_scope_id" {
  command = plan

  variables {
    exemptions = {
      bad = {
        scope_type           = "management_group"
        policy_assignment_id = "/providers/Microsoft.Management/managementGroups/corp/providers/Microsoft.Authorization/policyAssignments/existing"
      }
    }
  }

  expect_failures = [var.exemptions]
}

run "rejects_exemption_with_no_assignment_reference" {
  command = plan

  variables {
    exemptions = {
      bad = {
        scope_type      = "subscription"
        subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
      }
    }
  }

  expect_failures = [var.exemptions]
}
