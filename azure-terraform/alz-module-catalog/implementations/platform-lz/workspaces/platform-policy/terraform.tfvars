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
  enabled = true

  policy_assignment_location    = "centralus"
  custom_policy_definitions     = {}
  custom_policy_set_definitions = {}

  # Built-in guardrails not covered by the governance policy_baseline (design
  # doc Phase 3 Step 7 identity/logging guardrails, Phase 5 Step 6-7 disk/DB
  # encryption). All effects below are Audit-equivalent (no Deny, no resource
  # changes, no cost) - report-only first per this repo's convention. GUIDs
  # verified against the current Azure built-in policy catalog on 2026-09-11
  # (see IDENTITY-RBAC-IAC-BOUNDARY.md for the ones NOT enabled and why).
  management_group_policy_assignments = {
    allowed_resource_types = {
      name                 = "cmp-allowed-res-types"
      management_group_key = "compeer-enterprise-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a08ec900-254a-4555-9bf5-e42af04b5c5c" # built-in "Allowed resource types"
      display_name         = "Compeer allowed resource types"
      enforce              = false # Audit only until the approved workload catalog below is confirmed complete
      parameters = {
        listOfResourceTypesAllowed = {
          # Approved workload catalog, per the ALZ design doc's workload
          # hosting patterns + platform services actually built in this repo.
          # Widen this list before switching enforce = true.
          value = [
            "Microsoft.Compute/virtualMachines",
            "Microsoft.Compute/disks",
            "Microsoft.Compute/virtualMachineScaleSets",
            "Microsoft.Network/virtualNetworks",
            "Microsoft.Network/networkSecurityGroups",
            "Microsoft.Network/routeTables",
            "Microsoft.Network/networkInterfaces",
            "Microsoft.Network/publicIPAddresses",
            "Microsoft.Network/loadBalancers",
            "Microsoft.Network/bastionHosts",
            "Microsoft.Network/privateEndpoints",
            "Microsoft.Network/privateDnsZones",
            "Microsoft.Network/applicationGateways",
            "Microsoft.Network/azureFirewalls",
            "Microsoft.Network/expressRouteCircuits",
            "Microsoft.Network/virtualNetworkGateways",
            "Microsoft.Network/connections",
            "Microsoft.Storage/storageAccounts",
            "Microsoft.KeyVault/vaults",
            "Microsoft.KeyVault/managedHSMs",
            "Microsoft.Sql/servers",
            "Microsoft.Sql/servers/databases",
            "Microsoft.Sql/managedInstances",
            "Microsoft.DocumentDB/databaseAccounts",
            "Microsoft.Web/sites",
            "Microsoft.Web/serverfarms",
            "Microsoft.ApiManagement/service",
            "Microsoft.ContainerService/managedClusters",
            "Microsoft.ContainerRegistry/registries",
            "Microsoft.OperationalInsights/workspaces",
            "Microsoft.Insights/actionGroups",
            "Microsoft.Insights/activityLogAlerts",
            "Microsoft.Insights/dataCollectionEndpoints",
            "Microsoft.Insights/dataCollectionRules",
            "Microsoft.Insights/diagnosticSettings",
            "Microsoft.Insights/metricAlerts",
            "Microsoft.Insights/scheduledQueryRules",
            "Microsoft.SecurityInsights/onboardingStates",
            "Microsoft.Automation/automationAccounts",
            "Microsoft.RecoveryServices/vaults",
            "Microsoft.Consumption/budgets",
            "Microsoft.Management/managementGroups",
            "Microsoft.Authorization/policyDefinitions",
            "Microsoft.Authorization/policySetDefinitions",
            "Microsoft.Authorization/policyAssignments",
            "Microsoft.Authorization/roleDefinitions",
            "Microsoft.Authorization/roleAssignments",
            "Microsoft.ManagedIdentity/userAssignedIdentities",
            "Microsoft.Compute/diskEncryptionSets",
            "Microsoft.EventGrid/topics",
            "Microsoft.EventGrid/systemTopics",
            "Microsoft.EventGrid/namespaces",
            "Microsoft.ServiceBus/namespaces",
            "Microsoft.Cache/redis",
            "Microsoft.DataFactory/factories",
            "Microsoft.Synapse/workspaces",
            "microsoft.aadiam/diagnosticSettings",
          ]
        }
      }
      non_compliance_messages = {
        default = { content = "This resource type is not on Compeer's approved workload catalog. Request an addition before deploying it in the landing zone." }
      }
    }
    disk_encryption_windows_vm = {
      name                 = "cmp-disk-encrypt-win"
      management_group_key = "workloads-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/3dc5edcd-002d-444c-b216-e123bbfa37c0" # built-in "Windows virtual machines should enable Azure Disk Encryption or EncryptionAtHost"
      display_name         = "Compeer require disk encryption - Windows VMs"
      identity             = { type = "SystemAssigned" } # Guest Configuration audit needs an identity to evaluate
    }
    disk_encryption_linux_vm = {
      name                 = "cmp-disk-encrypt-linux"
      management_group_key = "workloads-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ca88aadc-6e2b-416c-9de2-5a0f01d1693f" # built-in "Linux virtual machines should enable Azure Disk Encryption or EncryptionAtHost"
      display_name         = "Compeer require disk encryption - Linux VMs"
      identity             = { type = "SystemAssigned" }
    }
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
      # Defender MG-scope auto-enablement (design doc Phase 6 Step 3-4).
      # NOT enabled here deliberately - see IDENTITY-RBAC-IAC-BOUNDARY.md.
      # The confirmed, non-deprecated built-in initiative is:
      #   "Configure Microsoft Defender for Cloud plans"
      #   /providers/Microsoft.Authorization/policySetDefinitions/f08c57cd-dbd6-49a4-a85e-9ae77ac959b0
      # It bundles 12 per-service DeployIfNotExists policies (Servers, Storage,
      # SQL, Key Vault, Containers, App Service, Cosmos DB, CSPM, ...) into one
      # assignment. What's blocking "live": (1) this resource's dine_assignments
      # only takes policy_definition_id, not policy_set_definition_id - assign
      # an initiative through the pattern's main management_group_policy_assignments
      # instead (it supports both + an identity block); (2) each per-service
      # policy needs a pricing tier / subplan (e.g. Servers P1 vs P2) - that is
      # a licensing/cost decision for Compeer, not a technical unknown, so it is
      # not defaulted here.
      # deploy_pdns_zonegroup_keyvault = {
      #   policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/<verify>"
      #   parameters = { privateDnsZoneId = { value = "/subscriptions/.../privateDnsZones/privatelink.vaultcore.azure.net" } }
      # }
    }
  }

  # -- Private-only connectivity guardrail (see pattern README) ---------------
  # Fully custom (no external policy ID dependency) - live in Audit mode,
  # report-only first per this repo's convention before ever considering Deny.
  private_only_connectivity = {
    enabled              = true
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
