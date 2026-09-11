# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id       -> shared HCP variable set (Terraform category, key: tenant_id)
#   subscription_id -> this workspace's Terraform-category variable in HCP
# The azurerm provider reads both from those Terraform variables.
#

location                  = "centralus"
tfe_organization          = "Compeer-Financial-Services"
governance_workspace_name = "platform-governance"
management_workspace_name = "platform-management"

# The deny/audit BASELINE (allowed-regions, required-tags, deny-public-PaaS,
# secure-storage, restrict-public-IP, private-SQL, MCSB) is shipped by the
# governance workspace's policy_baseline. This workspace owns:
#   - promotion of those baseline policies to Deny (via governance, per policy)
#   - DeployIfNotExists remediation (needs a managed identity + Log Analytics)
#   - policy exemptions (all three scopes)
#   - the private-only-connectivity guardrail
policy = {
  enabled = false

  policy_assignment_location    = "centralus"
  custom_policy_definitions     = {}
  custom_policy_set_definitions = {}

  # Built-in guardrails not covered by the governance policy_baseline (design
  # doc Phase 3 Step 7 identity/logging guardrails, Phase 5 Step 6-7 disk/DB
  # encryption). Built-in policy GUIDs are global (same across tenants), but
  # per this repo's convention, confirm each one before enabling:
  #   az policy definition list --query "[?displayName=='<name>'].{name:displayName,id:id}" -o table
  management_group_policy_assignments = {
    # allowed_resource_types = {
    #   name                  = "cmp-allowed-resource-types"
    #   management_group_key  = "compeer-enterprise-mg"
    #   policy_definition_id  = "/providers/Microsoft.Authorization/policyDefinitions/a08ec900-254a-4555-9bf5-e42af04b5c5c" # built-in "Allowed resource types"
    #   display_name          = "Compeer allowed resource types"
    #   parameters = {
    #     listOfResourceTypesAllowed = { value = [] } # populate from the approved workload catalog
    #   }
    # }
    # disk_encryption_required = {
    #   name                  = "cmp-disk-encryption"
    #   management_group_key  = "workloads-mg"
    #   policy_definition_id  = "/providers/Microsoft.Authorization/policyDefinitions/<verify: 'Disk encryption should be enabled'>"
    #   display_name          = "Compeer require disk encryption"
    # }
    # sql_tde_required = {
    #   name                  = "cmp-sql-tde"
    #   management_group_key  = "workloads-mg"
    #   policy_definition_id  = "/providers/Microsoft.Authorization/policyDefinitions/<verify: 'Transparent Data Encryption on SQL databases should be enabled'>"
    #   display_name          = "Compeer require SQL TDE"
    # }
    # managed_identity_required = {
    #   name                  = "cmp-managed-identity"
    #   management_group_key  = "workloads-mg"
    #   policy_definition_id  = "/providers/Microsoft.Authorization/policyDefinitions/<verify: identity-usage audit initiative>"
    #   display_name          = "Compeer audit managed identity usage"
    # }
    # diagnostic_settings_required = {
    #   name                  = "cmp-require-diagnostics"
    #   management_group_key  = "compeer-enterprise-mg"
    #   policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/<verify: 'Deploy Diagnostic Settings' initiative>"
    #   display_name          = "Compeer require diagnostic settings"
    # }
  }
  subscription_policy_assignments   = {}
  resource_group_policy_assignments = {}

  # -- Exemptions (mandatory before promoting any baseline policy to Deny) -----
  policy_exemptions = {
    # legacy-sandbox-waiver = {
    #   scope_type            = "subscription"
    #   subscription_id       = "/subscriptions/<guid>"
    #   policy_assignment_id  = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg/providers/Microsoft.Authorization/policyAssignments/cmp-deny-pip"
    #   exemption_category    = "Waiver"
    #   expires_on            = "2026-12-31T00:00:00Z"
    #   description           = "Sandbox lab needs public IPs until migration; tracked in RISK-1234."
    # }
  }

  # -- DeployIfNotExists remediation -----------------------------------------
  # log_analytics_workspace_id is auto-read from the platform-management output.
  # Verify each built-in policy ID against the tenant:
  #   az policy definition list --query "[?policyRule.then.effect=='DeployIfNotExists'].{name:displayName,id:id}" -o table
  remediation = {
    enabled              = false
    management_group_key = "compeer-enterprise-mg"
    location             = "centralus"
    dine_assignments = {
      # activity_log_to_law = {
      #   policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2465583e-4e78-4c15-b6be-a36cbc7c8b0f"
      #   inject_law          = true   # adds { logAnalytics = { value = <workspace id> } }
      # }
      # Defender MG-scope auto-enablement (design doc Phase 6 Step 3-4). Each
      # of these is a built-in "Configure Microsoft Defender for X to be
      # enabled" DINE policy - confirm the exact ID per plan before enabling:
      #   az policy definition list --query "[?contains(displayName,'Configure Microsoft Defender')].{name:displayName,id:id}" -o table
      # defender_for_servers = {
      #   policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/<verify: 'Configure Microsoft Defender for Servers to be enabled'>"
      # }
      # defender_for_storage = {
      #   policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/<verify: 'Configure Microsoft Defender for Storage to be enabled'>"
      # }
      # defender_for_sql = {
      #   policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/<verify: 'Configure Microsoft Defender for SQL Servers to be enabled'>"
      # }
      # defender_for_key_vault = {
      #   policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/<verify: 'Configure Microsoft Defender for Key Vaults to be enabled'>"
      # }
      # deploy_pdns_zonegroup_keyvault = {
      #   policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/<verify>"
      #   parameters = { privateDnsZoneId = { value = "/subscriptions/.../privateDnsZones/privatelink.vaultcore.azure.net" } }
      # }
    }
  }

  # -- Private-only connectivity guardrail (see pattern README) ---------------
  private_only_connectivity = {
    enabled              = false
    management_group_key = "compeer-enterprise-mg"
    effect               = "Audit"
    enforce              = true
    allowed_public_ip_resource_group_names = [
      "rg-conn-palo-alto",
      "rg-conn-bastion",
      "rg-conn-route-server",
      "rg-hybrid-gateway",
    ]
    not_scopes                    = []
    include_builtin_baseline      = false
    builtin_policy_definition_ids = {}
  }
}
