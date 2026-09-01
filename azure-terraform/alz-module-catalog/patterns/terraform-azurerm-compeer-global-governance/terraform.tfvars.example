management_groups = {
  "compeer-enterprise-mg" = {
    display_name = "Compeer Enterprise"
  }

  "platform-mg" = {
    display_name = "Platform"
    parent_key   = "compeer-enterprise-mg"
  }
  "security-mg" = {
    display_name = "Security"
    parent_key   = "platform-mg"
  }
  "identity-mg" = {
    display_name = "Identity"
    parent_key   = "platform-mg"
  }
  "management-mg" = {
    display_name = "Management"
    parent_key   = "platform-mg"
  }
  "connectivity-mg" = {
    display_name = "Connectivity"
    parent_key   = "platform-mg"
  }

  "workloads-mg" = {
    display_name = "Workloads"
    parent_key   = "compeer-enterprise-mg"
  }
  "internal-apps-mg" = {
    display_name = "Internal Apps"
    parent_key   = "workloads-mg"
  }
  "internal-apps-dev-mg" = {
    display_name = "Internal Apps - Dev"
    parent_key   = "internal-apps-mg"
  }
  "internal-apps-test-mg" = {
    display_name = "Internal Apps - Test"
    parent_key   = "internal-apps-mg"
  }
  "internal-apps-prod-mg" = {
    display_name = "Internal Apps - Prod"
    parent_key   = "internal-apps-mg"
  }

  "external-apps-mg" = {
    display_name = "External Apps"
    parent_key   = "workloads-mg"
  }
  "external-apps-dev-mg" = {
    display_name = "External Apps - Dev"
    parent_key   = "external-apps-mg"
  }
  "external-apps-test-mg" = {
    display_name = "External Apps - Test"
    parent_key   = "external-apps-mg"
  }
  "external-apps-prod-mg" = {
    display_name = "External Apps - Prod"
    parent_key   = "external-apps-mg"
  }

  "regulated-apps-mg" = {
    display_name = "Regulated Apps"
    parent_key   = "workloads-mg"
  }
  "regulated-apps-dev-mg" = {
    display_name = "Regulated Apps - Dev"
    parent_key   = "regulated-apps-mg"
  }
  "regulated-apps-test-mg" = {
    display_name = "Regulated Apps - Test"
    parent_key   = "regulated-apps-mg"
  }
  "regulated-apps-prod-mg" = {
    display_name = "Regulated Apps - Prod"
    parent_key   = "regulated-apps-mg"
  }

  "shared-services-mg" = {
    display_name = "Shared Services"
    parent_key   = "workloads-mg"
  }
  "shared-services-dev-mg" = {
    display_name = "Shared Services - Dev"
    parent_key   = "shared-services-mg"
  }
  "shared-services-test-mg" = {
    display_name = "Shared Services - Test"
    parent_key   = "shared-services-mg"
  }
  "shared-services-prod-mg" = {
    display_name = "Shared Services - Prod"
    parent_key   = "shared-services-mg"
  }

  "sandbox-mg" = {
    display_name = "Sandbox"
    parent_key   = "compeer-enterprise-mg"
  }
  "decommissioned-mg" = {
    display_name = "Decommissioned"
    parent_key   = "compeer-enterprise-mg"
  }
}

subscription_placements = {}

custom_policy_definitions = {
  allowed_locations = {
    display_name         = "Compeer - Allowed Azure regions"
    management_group_key = "compeer-enterprise-mg"
    description          = "Restricts landing-zone deployments to approved Compeer regions."
    metadata = {
      category = "Compeer Landing Zone"
      version  = "1.0.0"
    }
    parameters = {
      allowedLocations = {
        type = "Array"
        metadata = {
          displayName = "Allowed locations"
        }
      }
      effect = {
        type          = "String"
        defaultValue  = "Deny"
        allowedValues = ["Audit", "Deny", "Disabled"]
      }
    }
    policy_rule = {
      if = {
        allOf = [
          {
            field  = "location"
            exists = "true"
          },
          {
            field = "location"
            notIn = "[parameters('allowedLocations')]"
          },
          {
            field     = "location"
            notEquals = "global"
          }
        ]
      }
      then = {
        effect = "[parameters('effect')]"
      }
    }
  }

  required_tags = {
    display_name         = "Compeer - Require standard resource tags"
    management_group_key = "compeer-enterprise-mg"
    description          = "Requires standard ownership, cost, data, and recovery tags."
    metadata = {
      category = "Compeer Landing Zone"
      version  = "1.0.0"
    }
    parameters = {
      requiredTagNames = {
        type = "Array"
        metadata = {
          displayName = "Required tag names"
        }
      }
      effect = {
        type          = "String"
        defaultValue  = "Deny"
        allowedValues = ["Audit", "Deny", "Disabled"]
      }
    }
    policy_rule = {
      if = {
        count = {
          value = "[parameters('requiredTagNames')]"
          name  = "requiredTagName"
          where = {
            value  = "[contains(field('tags'), current('requiredTagName'))]"
            equals = false
          }
        }
        greater = 0
      }
      then = {
        effect = "[parameters('effect')]"
      }
    }
  }

  deny_public_paas = {
    display_name         = "Compeer - Deny public network access for sensitive PaaS"
    management_group_key = "compeer-enterprise-mg"
    description          = "Denies public network exposure for common sensitive PaaS resources."
    metadata = {
      category = "Compeer Landing Zone"
      version  = "1.0.0"
    }
    parameters = {
      effect = {
        type          = "String"
        defaultValue  = "Deny"
        allowedValues = ["Audit", "Deny", "Disabled"]
      }
    }
    policy_rule = {
      if = {
        anyOf = [
          {
            allOf = [
              {
                field  = "type"
                equals = "Microsoft.Storage/storageAccounts"
              },
              {
                field     = "Microsoft.Storage/storageAccounts/publicNetworkAccess"
                notEquals = "Disabled"
              }
            ]
          },
          {
            allOf = [
              {
                field  = "type"
                equals = "Microsoft.KeyVault/vaults"
              },
              {
                field     = "Microsoft.KeyVault/vaults/publicNetworkAccess"
                notEquals = "Disabled"
              }
            ]
          },
          {
            allOf = [
              {
                field  = "type"
                equals = "Microsoft.Web/sites"
              },
              {
                field     = "Microsoft.Web/sites/publicNetworkAccess"
                notEquals = "Disabled"
              }
            ]
          }
        ]
      }
      then = {
        effect = "[parameters('effect')]"
      }
    }
  }

  secure_storage = {
    display_name         = "Compeer - Enforce secure storage account baseline"
    management_group_key = "compeer-enterprise-mg"
    description          = "Requires HTTPS-only storage and TLS 1.2 or higher."
    metadata = {
      category = "Compeer Landing Zone"
      version  = "1.0.0"
    }
    parameters = {
      effect = {
        type          = "String"
        defaultValue  = "Deny"
        allowedValues = ["Audit", "Deny", "Disabled"]
      }
    }
    policy_rule = {
      if = {
        allOf = [
          {
            field  = "type"
            equals = "Microsoft.Storage/storageAccounts"
          },
          {
            anyOf = [
              {
                field     = "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly"
                notEquals = true
              },
              {
                field     = "Microsoft.Storage/storageAccounts/minimumTlsVersion"
                notEquals = "TLS1_2"
              },
              {
                field     = "Microsoft.Storage/storageAccounts/allowBlobPublicAccess"
                notEquals = false
              }
            ]
          }
        ]
      }
      then = {
        effect = "[parameters('effect')]"
      }
    }
  }

  deny_public_ip = {
    display_name         = "Compeer - Restrict public IP creation"
    management_group_key = "compeer-enterprise-mg"
    description          = "Audits or denies public IP address resources unless explicitly approved."
    metadata = {
      category = "Compeer Landing Zone"
      version  = "1.0.0"
    }
    parameters = {
      effect = {
        type          = "String"
        defaultValue  = "Deny"
        allowedValues = ["Audit", "Deny", "Disabled"]
      }
    }
    policy_rule = {
      if = {
        field  = "type"
        equals = "Microsoft.Network/publicIPAddresses"
      }
      then = {
        effect = "[parameters('effect')]"
      }
    }
  }

  sql_private_network = {
    display_name         = "Compeer - Require private SQL network posture"
    management_group_key = "compeer-enterprise-mg"
    description          = "Audits or denies Azure SQL servers that allow public network access."
    metadata = {
      category = "Compeer Landing Zone"
      version  = "1.0.0"
    }
    parameters = {
      effect = {
        type          = "String"
        defaultValue  = "Deny"
        allowedValues = ["Audit", "Deny", "Disabled"]
      }
    }
    policy_rule = {
      if = {
        allOf = [
          {
            field  = "type"
            equals = "Microsoft.Sql/servers"
          },
          {
            field     = "Microsoft.Sql/servers/publicNetworkAccess"
            notEquals = "Disabled"
          }
        ]
      }
      then = {
        effect = "[parameters('effect')]"
      }
    }
  }
}

management_group_policy_assignments = {
  allowed_locations_nonprod = {
    name                  = "cmp-allowloc-np"
    management_group_key  = "workloads-mg"
    policy_definition_key = "allowed_locations"
    display_name          = "Compeer allowed locations - NonProd"
    parameters = {
      allowedLocations = {
        value = ["centralus"]
      }
      effect = {
        value = "Deny"
      }
    }
    non_compliance_messages = {
      default = {
        content = "Deploy resources only in Compeer-approved regions."
      }
    }
  }

  required_tags_nonprod = {
    name                  = "cmp-reqtags-np"
    management_group_key  = "workloads-mg"
    policy_definition_key = "required_tags"
    display_name          = "Compeer required tags - NonProd"
    parameters = {
      requiredTagNames = {
        value = [
          "env",
          "application",
          "bt_owner",
          "source_repo",
          "tf_workspace",
          "recovery",
          "cost_center",
          "data_classification",
          "compliance_boundary"
        ]
      }
      effect = {
        value = "Deny"
      }
    }
  }

  deny_public_paas_nonprod = {
    name                  = "cmp-denypaas-np"
    management_group_key  = "workloads-mg"
    policy_definition_key = "deny_public_paas"
    display_name          = "Compeer deny public PaaS - NonProd"
    parameters = {
      effect = {
        value = "Deny"
      }
    }
  }

  secure_storage_nonprod = {
    name                  = "cmp-secstorage-np"
    management_group_key  = "workloads-mg"
    policy_definition_key = "secure_storage"
    display_name          = "Compeer secure storage - NonProd"
    parameters = {
      effect = {
        value = "Deny"
      }
    }
  }

  deny_public_ip_nonprod = {
    name                  = "cmp-denypip-np"
    management_group_key  = "workloads-mg"
    policy_definition_key = "deny_public_ip"
    display_name          = "Compeer restrict public IP - NonProd"
    parameters = {
      effect = {
        value = "Deny"
      }
    }
  }

  sql_private_network_nonprod = {
    name                  = "cmp-sqlprivate-np"
    management_group_key  = "workloads-mg"
    policy_definition_key = "sql_private_network"
    display_name          = "Compeer private SQL network - NonProd"
    parameters = {
      effect = {
        value = "Deny"
      }
    }
  }
}

custom_role_definitions = {
  policy_remediation_operator = {
    name                 = "Compeer Policy Remediation Operator"
    management_group_key = "compeer-enterprise-mg"
    description          = "Can read policy state and create policy remediation deployments without broad Owner access."
    permissions = {
      remediation = {
        actions = [
          "Microsoft.Authorization/policyAssignments/read",
          "Microsoft.Authorization/policyDefinitions/read",
          "Microsoft.Authorization/policySetDefinitions/read",
          "Microsoft.PolicyInsights/*/read",
          "Microsoft.PolicyInsights/remediations/*",
          "Microsoft.Resources/deployments/*",
          "Microsoft.Resources/subscriptions/resourceGroups/read"
        ]
        not_actions = [
          "Microsoft.Authorization/*/delete",
          "Microsoft.Authorization/*/write"
        ]
      }
    }
  }
}

role_assignments = {}

management_group_budgets = {
  nonprod_monthly = {
    management_group_key = "workloads-mg"
    amount               = 25000
    time_grain           = "Monthly"
    time_period = {
      start_date = "2026-07-01T00:00:00Z"
    }
    notifications = {
      actual_80 = {
        threshold      = 80
        operator       = "GreaterThan"
        threshold_type = "Actual"
        contact_emails = ["cloudops@compeer.example"]
      }
      forecast_100 = {
        threshold      = 100
        operator       = "GreaterThan"
        threshold_type = "Forecasted"
        contact_emails = ["cloudops@compeer.example"]
      }
    }
  }
}
