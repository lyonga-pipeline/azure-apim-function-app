location                  = "centralus"
tfe_organization          = "Compeer-Financial-Services"
governance_workspace_name = "platform-governance"
management_workspace_name = "platform-management"

policy = {
  enabled = true

  policy_assignment_location    = "centralus"
  custom_policy_definitions     = {}
  custom_policy_set_definitions = {}

  # Enterprise controls not owned by the initial governance baseline.
  management_group_policy_assignments = {
    allowed_resource_types = {
      name                 = "cmp-allowed-res-types"
      management_group_key = "compeer-enterprise-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a08ec900-254a-4555-9bf5-e42af04b5c5c" # built-in "Allowed resource types"
      display_name         = "Compeer allowed resource types"
      enforce              = false
      parameters = {
        listOfResourceTypesAllowed = {
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
    app_service_managed_identity = {
      name                 = "cmp-mi-web"
      management_group_key = "compeer-enterprise-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2b9ad585-36bc-4615-b300-fd4435808332"
      display_name         = "Compeer audit managed identity on App Service"
    }
    function_app_managed_identity = {
      name                 = "cmp-mi-function"
      management_group_key = "compeer-enterprise-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0da106f2-4ca3-48e8-bc85-c638fe6aea8f"
      display_name         = "Compeer audit managed identity on Function Apps"
    }
    automation_managed_identity = {
      name                 = "cmp-mi-automation"
      management_group_key = "compeer-enterprise-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/dea83a72-443c-4292-83d5-54a2f98749c0"
      display_name         = "Compeer audit managed identity on Automation Accounts"
    }
    key_vault_rbac = {
      name                 = "cmp-kv-rbac"
      management_group_key = "compeer-enterprise-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/12d4fa5e-1f9f-4c21-97a9-b99b3c6611b5"
      display_name         = "Compeer audit Key Vault RBAC authorization"
    }
    key_vault_deletion_protection = {
      name                 = "cmp-kv-recovery"
      management_group_key = "compeer-enterprise-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0b60c0b2-2dc2-4e1c-b5c9-abbed971de53"
      display_name         = "Compeer audit Key Vault deletion protection"
    }
    app_service_latest_tls = {
      name                 = "cmp-tls-web"
      management_group_key = "compeer-enterprise-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/f0e6e85b-9b9f-4a4b-b67b-f730d42f1b0b"
      display_name         = "Compeer audit latest TLS on App Service"
    }
    function_app_latest_tls = {
      name                 = "cmp-tls-function"
      management_group_key = "compeer-enterprise-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/f9d614c5-c173-4d56-95a7-b4437057d193"
      display_name         = "Compeer audit latest TLS on Function Apps"
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
    # Workload VMs inherit this audit; platform VM backup is configured explicitly.
    vm_backup_required = {
      name                 = "cmp-vm-backup"
      management_group_key = "workloads-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/013e242c-8828-4970-87b3-ab247555486d"
      display_name         = "Compeer require VM backup"
    }
    # Reporting-only benchmark; the MCSB baseline remains in platform-governance.
    cis_benchmark = {
      name                     = "cmp-cis-benchmark"
      management_group_key     = "compeer-enterprise-mg"
      policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/06f19060-9e68-4070-92ca-f15cc126059e"
      display_name             = "CIS Microsoft Azure Foundations Benchmark v2.0.0"
      enforce                  = false
    }
  }
  subscription_policy_assignments   = {}
  resource_group_policy_assignments = {}

  # Add approved, time-bound exemptions before promoting a control to Deny.
  policy_exemptions = {}

  # The root obtains the Log Analytics workspace ID from platform-management.
  remediation = {
    enabled              = true
    management_group_key = "compeer-enterprise-mg"
    location             = "centralus"
    dine_assignments = {
      diagnostics_to_log_analytics = {
        policy_set_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/0884adba-2312-4468-abeb-5422caed1038"
        display_name             = "Compeer deploy diagnostics to central Log Analytics"
        description              = "GOV-07 backstop: deploy allLogs and supported metrics only when no compliant diagnostic setting targets the central workspace."
        inject_law               = true
        role_definition_ids = [
          "/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293",
        ]
        parameters = {
          effect = { value = "DeployIfNotExists" }
          diagnosticSettingName = {
            value = "setByPolicy-LogAnalytics"
          }
          resourceLocationList = { value = ["*"] }
          resourceTypeList = {
            value = [
              "microsoft.apimanagement/service",
              "microsoft.automation/automationaccounts",
              "microsoft.containerregistry/registries",
              "microsoft.datafactory/factories",
              "microsoft.eventgrid/systemtopics",
              "microsoft.eventgrid/topics",
              "microsoft.keyvault/vaults",
              "microsoft.network/applicationgateways",
              "microsoft.network/azurefirewalls",
              "microsoft.network/bastionhosts",
              "microsoft.network/expressroutecircuits",
              "microsoft.network/loadbalancers",
              "microsoft.network/networksecuritygroups",
              "microsoft.network/publicipaddresses",
              "microsoft.network/virtualnetworkgateways",
              "microsoft.network/virtualnetworks",
              "microsoft.recoveryservices/vaults",
              "microsoft.servicebus/namespaces",
              "microsoft.sql/managedinstances",
              "microsoft.sql/servers/databases",
              "microsoft.synapse/workspaces",
            ]
          }
        }
      }
    }
  }

  # Audit public IP usage before considering Deny.
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
