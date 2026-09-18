mock_provider "azurerm" {}

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  management_group_ids = {
    platform = "/providers/Microsoft.Management/managementGroups/platform"
  }
}

run "explicit_name_wins_over_naming_default" {
  command = plan

  variables {
    custom_policy_set_definitions = {
      cmp-lz-baseline = {
        name                         = "cmp-lz-baseline"
        display_name                 = "Compeer landing zone baseline"
        management_group_key         = "platform"
        policy_definition_references = [{ policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000" }]
      }
    }
  }

  assert {
    condition     = local.policy_set_definitions_input["cmp-lz-baseline"].name == "cmp-lz-baseline"
    error_message = "an explicit name must win over the naming module default"
  }
}

run "initiative_name_defaults_to_naming_module_when_domain_is_set" {
  command = plan

  variables {
    custom_policy_set_definitions = {
      security_baseline = {
        domain                       = "security"
        display_name                 = "Security baseline"
        management_group_key         = "platform"
        policy_definition_references = [{ policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000" }]
      }
    }
  }

  assert {
    condition     = local.policy_set_definitions_input["security_baseline"].name == "initiative-security-security_baseline"
    error_message = "an entry with domain set but no explicit name should default to the naming module's policy_initiative pattern"
  }
}

run "initiative_name_falls_back_to_key_without_domain_or_explicit_name" {
  command = plan

  variables {
    custom_policy_set_definitions = {
      untouched_key = {
        display_name                 = "No domain, no explicit name"
        management_group_key         = "platform"
        policy_definition_references = [{ policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000" }]
      }
    }
  }

  assert {
    condition     = local.policy_set_definitions_input["untouched_key"].name == "untouched_key"
    error_message = "without domain or an explicit name, the map key itself remains the last-resort name (unchanged pre-existing behaviour)"
  }
}

run "assignment_name_defaults_to_naming_module_when_policy_and_scope_are_set" {
  command = plan

  variables {
    management_group_policy_assignments = {
      allowed_locations = {
        # Short tokens on purpose: azurerm_management_group_policy_assignment
        # enforces a real, hard 24-char name limit (confirmed empirically -
        # this is NOT documented as a universal Azure Policy assignment limit
        # and does NOT apply to subscription/resource-group scoped
        # assignments) - "assign-loc-plt" (14 chars) fits; the naming
        # module's assign-<policy>-<scope> pattern has no length guard of its
        # own since it doesn't know which scope will consume it.
        policy                = "loc"
        policy_scope          = "plt"
        management_group_key  = "platform"
        policy_definition_key = null
        policy_definition_id  = "/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000"
      }
    }
  }

  assert {
    condition     = local.management_group_policy_assignments_input["allowed_locations"].name == "assign-loc-plt"
    error_message = "an assignment with policy+policy_scope set but no explicit name should default to the naming module's policy_assignment pattern"
  }
}
