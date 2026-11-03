mock_provider "azurerm" {}
mock_provider "tfe" {}

variables {
  tenant_id                 = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  execution_subscription_id = "11111111-1111-1111-1111-111111111111"
  use_tfe_outputs           = false
  policy                    = { enabled = true }
  management_group_ids      = { workloads = "/providers/Microsoft.Management/managementGroups/workloads" }
}

run "dns_registration_is_opt_in" {
  command = plan
  assert {
    condition     = length(local.private_endpoint_dns_dine_assignments) == 0 && length(azurerm_role_assignment.private_endpoint_dns_zone) == 0 && length(output.private_endpoint_dns_registration) == 0
    error_message = "Adding the extension must not change existing deployed DNS ownership."
  }
}

run "approved_existing_zones_get_builtin_assignments_and_zone_scoped_roles" {
  command = plan
  variables {
    private_endpoint_dns_policies = {
      apps = {
        management_group_key = "workloads"
        approval_reference   = "TEST-CHANGE-123"
        not_scopes           = ["/subscriptions/44444444-4444-4444-4444-444444444444"]
        zone_ids = {
          key_vault    = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/manual-dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
          storage_blob = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/legacy-dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
        }
      }
    }
  }
  assert {
    condition = (
      length(local.private_endpoint_dns_dine_assignments) == 2 && local.remediation.enabled &&
      length(module.policy[0].remediation_assignment_ids) == 2 &&
      length(azurerm_role_assignment.private_endpoint_dns_zone) == 2 &&
      alltrue([for role in values(azurerm_role_assignment.private_endpoint_dns_zone) : role.role_definition_name == "Private DNS Zone Contributor" && strcontains(role.scope, "/privateDnsZones/")]) &&
      alltrue([for assignment in values(local.private_endpoint_dns_dine_assignments) : assignment.parameters.effect.value == "DeployIfNotExists" && assignment.not_scopes == tolist(["/subscriptions/44444444-4444-4444-4444-444444444444"])]) &&
      length(local.remediation.tasks) == 0
    )
    error_message = "DNS adoption must create only approved built-in DINE assignments and zone-scoped grants, preserve exclusions and never auto-backfill existing endpoints."
  }
}

run "legacy_zone_owner_can_grant_permissions_externally" {
  command = plan
  variables {
    private_endpoint_dns_policies = {
      apps = {
        management_group_key         = "workloads"
        approval_reference           = "TEST-EXTERNAL-123"
        manage_zone_role_assignments = false
        zone_ids                     = { key_vault = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/manual-dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
      }
    }
  }
  assert {
    condition     = length(azurerm_role_assignment.private_endpoint_dns_zone) == 0 && output.private_endpoint_dns_registration["apps.key_vault"].zone_permissions_owner == "existing-zone-owner" && length(module.policy[0].remediation_assignment_ids) == 1
    error_message = "External zone RBAC must not require adoption of legacy DNS resources or duplicate grants."
  }
}

run "wrong_service_zone_is_rejected" {
  command = plan
  variables {
    private_endpoint_dns_policies = {
      apps = {
        management_group_key = "workloads"
        approval_reference   = "TEST"
        zone_ids             = { key_vault = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net" }
      }
    }
  }
  expect_failures = [var.private_endpoint_dns_policies]
}

run "disabled_policy_owner_cannot_accept_dns_configuration" {
  command = plan
  variables {
    policy = { enabled = false }
    private_endpoint_dns_policies = {
      apps = {
        management_group_key = "workloads"
        approval_reference   = "TEST"
        zone_ids             = { key_vault = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
      }
    }
  }
  expect_failures = [terraform_data.private_endpoint_dns_contract]
}

run "dns_backfill_waits_for_permission_bootstrap_approval" {
  command = plan
  variables {
    policy = {
      enabled = true
      remediation = {
        tasks = {
          dns-pilot = {
            assignment_key       = "dns-${substr(sha256("apps"), 0, 8)}-kv"
            resource_count       = 1
            parallel_deployments = 1
            failure_percentage   = 0
          }
        }
      }
    }
    private_endpoint_dns_policies = {
      apps = {
        management_group_key = "workloads"
        approval_reference   = "TEST"
        zone_ids             = { key_vault = "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/dns/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net" }
      }
    }
  }
  expect_failures = [terraform_data.private_endpoint_dns_contract]
}
