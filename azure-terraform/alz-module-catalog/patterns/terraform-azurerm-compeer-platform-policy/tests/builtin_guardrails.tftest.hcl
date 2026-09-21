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
# approved resource types, managed identity, Key Vault recovery/RBAC, TLS,
# disk encryption, backup, and compliance reporting controls.
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
      app_service_managed_identity = {
        name                 = "cmp-mi-web"
        management_group_key = "compeer-enterprise-mg"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2b9ad585-36bc-4615-b300-fd4435808332"
      }
      function_app_managed_identity = {
        name                 = "cmp-mi-function"
        management_group_key = "compeer-enterprise-mg"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0da106f2-4ca3-48e8-bc85-c638fe6aea8f"
      }
      automation_managed_identity = {
        name                 = "cmp-mi-automation"
        management_group_key = "compeer-enterprise-mg"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/dea83a72-443c-4292-83d5-54a2f98749c0"
      }
      key_vault_rbac = {
        name                 = "cmp-kv-rbac"
        management_group_key = "compeer-enterprise-mg"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/12d4fa5e-1f9f-4c21-97a9-b99b3c6611b5"
      }
      key_vault_deletion_protection = {
        name                 = "cmp-kv-recovery"
        management_group_key = "compeer-enterprise-mg"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0b60c0b2-2dc2-4e1c-b5c9-abbed971de53"
      }
      app_service_latest_tls = {
        name                 = "cmp-tls-web"
        management_group_key = "compeer-enterprise-mg"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/f0e6e85b-9b9f-4a4b-b67b-f730d42f1b0b"
      }
      function_app_latest_tls = {
        name                 = "cmp-tls-function"
        management_group_key = "compeer-enterprise-mg"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/f9d614c5-c173-4d56-95a7-b4437057d193"
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
      vm_backup_required = {
        name                 = "cmp-vm-backup"
        management_group_key = "workloads-mg"
        policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/013e242c-8828-4970-87b3-ab247555486d"
        display_name         = "Compeer require VM backup"
      }
      cis_benchmark = {
        name                     = "cmp-cis-benchmark"
        management_group_key     = "compeer-enterprise-mg"
        policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/06f19060-9e68-4070-92ca-f15cc126059e"
        display_name             = "CIS Microsoft Azure Foundations Benchmark v2.0.0"
        enforce                  = false
      }
    }
  }

  assert {
    condition     = length(local.management_group_policy_assignments_input) == 12
    error_message = "expected the 12 built-in guardrail assignments to be created"
  }
  assert {
    condition     = local.management_group_policy_assignments_input["cis_benchmark"].enforce == false
    error_message = "CIS benchmark is a reporting initiative, never enforced"
  }
  assert {
    condition     = local.management_group_policy_assignments_input["allowed_resource_types"].enforce == false
    error_message = "allowed_resource_types should stay Audit-only (enforce=false) until the catalog is confirmed"
  }
  assert {
    condition     = local.management_group_policy_assignments_input["disk_encryption_windows_vm"].identity.type == "SystemAssigned"
    error_message = "disk encryption guest-configuration audits need a system-assigned identity to evaluate"
  }
  assert {
    condition = alltrue([
      for key in [
        "app_service_managed_identity",
        "function_app_managed_identity",
        "automation_managed_identity",
        "key_vault_rbac",
        "key_vault_deletion_protection",
        "app_service_latest_tls",
        "function_app_latest_tls",
      ] : local.management_group_policy_assignments_input[key].management_group_id == "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg"
    ])
    error_message = "enterprise baseline identity, Key Vault, and TLS audits must be assigned at compeer-enterprise-mg"
  }
}
