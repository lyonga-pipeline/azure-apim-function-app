mock_provider "azurerm" {}

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  management_group_ids = {
    compeer-enterprise-mg = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg"
    workloads-mg          = "/providers/Microsoft.Management/managementGroups/workloads-mg"
  }
}

# Exercises the exact shape deployed in
# implementations/platform-lz/workspaces/platform-policy/terraform.tfvars:
# allowed-resource-types (Audit, enforce=false, no identity) and the two
# disk-encryption Guest Configuration audits (identity = SystemAssigned).
run "builtin_audit_guardrails" {
  command = plan

  variables {
    management_group_policy_assignments = {
      allowed_resource_types = {
        name                 = "cmp-allowed-res-types"
        management_group_key = "compeer-enterprise-mg"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a08ec900-254a-4555-9bf5-e42af04b5c5c"
        display_name         = "Compeer allowed resource types"
        enforce              = false
        parameters = {
          listOfResourceTypesAllowed = {
            value = ["Microsoft.Compute/virtualMachines", "Microsoft.Storage/storageAccounts"]
          }
        }
        non_compliance_messages = {
          default = { content = "Not on the approved catalog." }
        }
      }
      disk_encryption_windows_vm = {
        name                 = "cmp-disk-encrypt-win"
        management_group_key = "workloads-mg"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/3dc5edcd-002d-444c-b216-e123bbfa37c0"
        display_name         = "Compeer require disk encryption - Windows VMs"
        identity             = { type = "SystemAssigned" }
      }
      disk_encryption_linux_vm = {
        name                 = "cmp-disk-encrypt-linux"
        management_group_key = "workloads-mg"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ca88aadc-6e2b-416c-9de2-5a0f01d1693f"
        display_name         = "Compeer require disk encryption - Linux VMs"
        identity             = { type = "SystemAssigned" }
      }
    }
  }

  assert {
    condition     = length(azurerm_management_group_policy_assignment.this) == 3
    error_message = "expected the 3 built-in guardrail assignments to be created"
  }
  assert {
    condition     = azurerm_management_group_policy_assignment.this["allowed_resource_types"].enforce == false
    error_message = "allowed_resource_types should stay Audit-only (enforce=false) until the catalog is confirmed"
  }
  assert {
    condition     = length(azurerm_management_group_policy_assignment.this["disk_encryption_windows_vm"].identity) == 1
    error_message = "disk encryption guest-configuration audits need a system-assigned identity to evaluate"
  }
}
