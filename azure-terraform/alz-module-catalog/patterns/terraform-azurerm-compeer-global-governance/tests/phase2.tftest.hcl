# PHASE2 EXISTING: Phase 2-only reference hierarchy. Do not remove already-deployed dormant branches from a live hierarchy.
mock_provider "azurerm" {}
variables {
  subscription_id          = "00000000-0000-0000-0000-000000000000"
  root_management_group_id = "tenant-root"
  management_groups = {
    compeer-enterprise-mg    = { parent_key = "root" }
    platform-mg              = { parent_key = "compeer-enterprise-mg" }
    platform-security-mg     = { parent_key = "platform-mg" }
    platform-identity-mg     = { parent_key = "platform-mg" }
    platform-management-mg   = { parent_key = "platform-mg" }
    platform-connectivity-mg = { parent_key = "platform-mg" }
    workloads-mg             = { parent_key = "compeer-enterprise-mg" }
    internal-apps-mg         = { parent_key = "workloads-mg" }
    external-apps-mg         = { parent_key = "workloads-mg" }
    sandbox-mg               = { parent_key = "compeer-enterprise-mg" }
    decommissioned-mg        = { parent_key = "compeer-enterprise-mg" }
    internal-apps-prod-mg    = { parent_key = "internal-apps-mg" }
    internal-apps-dev-mg     = { parent_key = "internal-apps-mg" }
    internal-apps-test-mg    = { parent_key = "internal-apps-mg" }
    internal-apps-uat-mg     = { parent_key = "internal-apps-mg" }
    external-apps-prod-mg    = { parent_key = "external-apps-mg" }
    external-apps-dev-mg     = { parent_key = "external-apps-mg" }
    external-apps-test-mg    = { parent_key = "external-apps-mg" }
    external-apps-uat-mg     = { parent_key = "external-apps-mg" }
  }
}
run "phase2_hierarchy_without_phase3_expansion" {
  command = plan
  assert {
    condition     = length(output.management_group_ids) == 19 && !contains(keys(output.management_group_ids), "shared-services-mg") && !contains(keys(output.management_group_ids), "data-mg")
    error_message = "Phase 2 expansion must work independently of deferred Phase 3 branches."
  }
}
