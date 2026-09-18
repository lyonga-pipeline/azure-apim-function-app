mock_provider "azurerm" {}
mock_provider "azuread" {}

variables {
  rbac_groups = {
    plt_readers   = { display_name = "AZ-PLT-Readers" }
    net_admins    = { display_name = "AZ-NET-Admins" }
    audit_readers = { display_name = "AZ-AUDIT-Readers" }
  }
  role_assignments = {
    plt_readers_platform = {
      scope                = "/providers/Microsoft.Management/managementGroups/platform-mg"
      group_key            = "plt_readers"
      role_definition_name = "Reader"
    }
    net_admins_platform = {
      scope                = "/providers/Microsoft.Management/managementGroups/platform-mg"
      group_key            = "net_admins"
      role_definition_name = "Network Contributor"
    }
    audit_readers_enterprise = {
      scope                = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg"
      group_key            = "audit_readers"
      role_definition_name = "Reader"
    }
  }
  operational_contracts = {
    break_glass = {
      phase                = "Phase 1"
      owner                = "Identity"
      implementation_state = "manual-control"
      required_controls    = ["two cloud-only accounts", "excluded from Conditional Access", "sign-in alert"]
      notes                = "IAM-04 accounts are created outside Terraform so access survives broken IaC or compromised automation."
    }
  }
}

run "groups_roles_and_contracts" {
  command = plan

  assert {
    condition     = length(module.rbac_groups) == 3
    error_message = "expected one Entra group per rbac_groups key"
  }
  assert {
    condition     = length(module.role_assignments.assignments) == 3
    error_message = "expected one role assignment per role_assignments key"
  }
  assert {
    condition     = contains(output.manual_control_keys, "break_glass")
    error_message = "break-glass should be surfaced as a manual control"
  }
}

run "rejects_both_principal_specifiers" {
  command = plan
  variables {
    role_assignments = {
      bad = {
        scope                = "/providers/Microsoft.Management/managementGroups/platform-mg"
        group_key            = "plt_readers"
        principal_id         = "00000000-0000-0000-0000-000000000000"
        role_definition_name = "Reader"
      }
    }
  }
  expect_failures = [var.role_assignments]
}

run "rejects_unknown_group_key" {
  command = plan
  variables {
    role_assignments = {
      bad = {
        scope                = "/providers/Microsoft.Management/managementGroups/platform-mg"
        group_key            = "does_not_exist"
        role_definition_name = "Reader"
      }
    }
  }
  expect_failures = [terraform_data.role_assignment_contract]
}

run "display_name_defaults_to_naming_module_pattern" {
  command = apply
  variables {
    rbac_groups = {
      plt_readers = { entra_domain = "plt", entra_role = "Readers" }
    }
    role_assignments = {}
  }
  assert {
    condition     = module.rbac_groups["plt_readers"].display_name == "AZ-PLT-Readers"
    error_message = "display_name should default to the naming module's entra_security_group pattern (AZ-<DOMAIN>-<Role>) when entra_domain/entra_role are set"
  }
}

run "explicit_display_name_overrides_naming_default" {
  command = apply
  variables {
    rbac_groups = {
      legacy_group = { display_name = "SG-Legacy-Custom-Name", entra_domain = "plt", entra_role = "Readers" }
    }
    role_assignments = {}
  }
  assert {
    condition     = module.rbac_groups["legacy_group"].display_name == "SG-Legacy-Custom-Name"
    error_message = "an explicit display_name must win over the naming-module default, even when entra_domain/entra_role are also set"
  }
}

run "custom_role_definition_wiring" {
  command = plan
  variables {
    custom_role_definitions = {
      platform_ops = {
        name        = "Compeer Platform Operator"
        scope       = "/providers/Microsoft.Management/managementGroups/platform-mg"
        permissions = { ops = { actions = ["Microsoft.Resources/subscriptions/resourceGroups/read"] } }
      }
    }
    role_assignments = {
      plt_ops = {
        scope               = "/providers/Microsoft.Management/managementGroups/platform-mg"
        group_key           = "plt_readers"
        role_definition_key = "platform_ops"
      }
    }
  }
  assert {
    condition     = length(module.custom_role_definitions) == 1
    error_message = "custom role definition should be created"
  }
  assert {
    condition     = length(module.role_assignments.assignments) == 1
    error_message = "custom-role assignment should resolve"
  }
}
