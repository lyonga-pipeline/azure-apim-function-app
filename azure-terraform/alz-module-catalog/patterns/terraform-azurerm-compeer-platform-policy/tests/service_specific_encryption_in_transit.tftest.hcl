mock_provider "azurerm" {}

# Regression lock for the SQL/APIM/Service Bus/Event Hub encryption-in-transit
# extension deployed to the live platform-policy workspace: built-in TLS
# audits for SQL Database, SQL Managed Instance, and APIM; custom TLS audits
# for Service Bus and Event Hub (no Microsoft built-in exists for those two);
# and the private-only-connectivity initiative's opt-in builtin baseline
# populated with SQL's disable-public-network-access builtins.

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  management_group_ids = {
    "compeer-enterprise-mg" = "/providers/Microsoft.Management/managementGroups/compeer-enterprise-mg"
  }

  custom_policy_definitions = {
    service_bus_minimum_tls = {
      display_name         = "Compeer - Service Bus namespaces should have minimum TLS version 1.2"
      mode                 = "Indexed"
      management_group_key = "compeer-enterprise-mg"
      description          = "Audits Service Bus namespaces whose minimumTlsVersion is not set to the required minimum."
      parameters = {
        effect = {
          type          = "String"
          allowedValues = ["Audit", "Disabled"]
          defaultValue  = "Audit"
          metadata      = { displayName = "Effect" }
        }
        minimumTlsVersion = {
          type          = "String"
          allowedValues = ["1.0", "1.1", "1.2"]
          defaultValue  = "1.2"
          metadata      = { displayName = "Minimum required TLS version" }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.ServiceBus/namespaces" },
            {
              not = {
                field  = "Microsoft.ServiceBus/namespaces/minimumTlsVersion"
                equals = "[parameters('minimumTlsVersion')]"
              }
            }
          ]
        }
        then = { effect = "[parameters('effect')]" }
      }
    }
    event_hub_minimum_tls = {
      display_name         = "Compeer - Event Hub namespaces should have minimum TLS version 1.2"
      mode                 = "Indexed"
      management_group_key = "compeer-enterprise-mg"
      description          = "Audits Event Hub namespaces whose minimumTlsVersion is not set to the required minimum."
      parameters = {
        effect = {
          type          = "String"
          allowedValues = ["Audit", "Disabled"]
          defaultValue  = "Audit"
          metadata      = { displayName = "Effect" }
        }
        minimumTlsVersion = {
          type          = "String"
          allowedValues = ["1.0", "1.1", "1.2"]
          defaultValue  = "1.2"
          metadata      = { displayName = "Minimum required TLS version" }
        }
      }
      policy_rule = {
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.EventHub/namespaces" },
            {
              not = {
                field  = "Microsoft.EventHub/namespaces/minimumTlsVersion"
                equals = "[parameters('minimumTlsVersion')]"
              }
            }
          ]
        }
        then = { effect = "[parameters('effect')]" }
      }
    }
  }

  management_group_policy_assignments = {
    sql_database_latest_tls = {
      name                 = "cmp-tls-sqldb"
      management_group_key = "compeer-enterprise-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/32e6bbec-16b6-44c2-be37-c5b672d103cf"
      display_name         = "Compeer audit latest TLS on Azure SQL Database"
    }
    sql_managed_instance_latest_tls = {
      name                 = "cmp-tls-sqlmi"
      management_group_key = "compeer-enterprise-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a8793640-60f7-487c-b5c3-1d37215905c4"
      display_name         = "Compeer audit latest TLS on SQL Managed Instance"
    }
    apim_encrypted_protocols_only = {
      name                 = "cmp-tls-apim"
      management_group_key = "compeer-enterprise-mg"
      policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ee7495e7-3ba7-40b6-bfee-c29e22cc75d4"
      display_name         = "Compeer audit APIM APIs use only encrypted protocols"
    }
    service_bus_minimum_tls = {
      name                  = "cmp-tls-svcbus"
      management_group_key  = "compeer-enterprise-mg"
      policy_definition_key = "service_bus_minimum_tls"
      display_name          = "Compeer audit minimum TLS version on Service Bus namespaces"
    }
    event_hub_minimum_tls = {
      name                  = "cmp-tls-eventhub"
      management_group_key  = "compeer-enterprise-mg"
      policy_definition_key = "event_hub_minimum_tls"
      display_name          = "Compeer audit minimum TLS version on Event Hub namespaces"
    }
  }

  private_only_connectivity = {
    enabled                  = true
    management_group_key     = "compeer-enterprise-mg"
    effect                   = "Audit"
    include_builtin_baseline = true
    builtin_policy_definition_ids = {
      sql_database_disable_public_network_access         = "/providers/Microsoft.Authorization/policyDefinitions/1b8ca024-1d5c-4dec-8995-b1a932b41780"
      sql_managed_instance_disable_public_network_access = "/providers/Microsoft.Authorization/policyDefinitions/9dfea752-dd46-4766-aed1-c355fa93fb91"
    }
  }
}

run "custom_tls_definitions_are_generated" {
  command = plan

  assert {
    condition     = contains(keys(local.policy_definitions_input), "service_bus_minimum_tls") && contains(keys(local.policy_definitions_input), "event_hub_minimum_tls")
    error_message = "Service Bus / Event Hub custom TLS definitions should reach the policy module"
  }
  assert {
    condition = (
      local.policy_definitions_input["service_bus_minimum_tls"].policy_rule.if.allOf[0].equals == "Microsoft.ServiceBus/namespaces" &&
      local.policy_definitions_input["service_bus_minimum_tls"].policy_rule.if.allOf[1].not.field == "Microsoft.ServiceBus/namespaces/minimumTlsVersion"
    )
    error_message = "Service Bus TLS definition must target the correct resource type and property"
  }
  assert {
    condition = (
      local.policy_definitions_input["event_hub_minimum_tls"].policy_rule.if.allOf[0].equals == "Microsoft.EventHub/namespaces" &&
      local.policy_definitions_input["event_hub_minimum_tls"].policy_rule.if.allOf[1].not.field == "Microsoft.EventHub/namespaces/minimumTlsVersion"
    )
    error_message = "Event Hub TLS definition must target the correct resource type and property"
  }
}

run "builtin_and_custom_tls_assignments_are_generated" {
  command = plan

  assert {
    condition = alltrue([
      for k in ["sql_database_latest_tls", "sql_managed_instance_latest_tls", "apim_encrypted_protocols_only", "service_bus_minimum_tls", "event_hub_minimum_tls"] :
      contains(keys(local.management_group_policy_assignments_input), k)
    ])
    error_message = "all five service-specific encryption-in-transit assignments should be generated"
  }
  assert {
    condition     = local.management_group_policy_assignments_input["sql_database_latest_tls"].policy_definition_id == "/providers/Microsoft.Authorization/policyDefinitions/32e6bbec-16b6-44c2-be37-c5b672d103cf"
    error_message = "SQL Database TLS assignment must reference the verified built-in policy id"
  }
  assert {
    # The module (not this pattern) resolves policy_definition_key -> id;
    # here we only confirm the pattern passes the right key through, same
    # idiom as private_only.tftest.hcl's policy_set_definition_key check.
    condition     = local.management_group_policy_assignments_input["service_bus_minimum_tls"].policy_definition_key == "service_bus_minimum_tls"
    error_message = "Service Bus TLS assignment must reference its sibling custom definition by key"
  }
}

run "private_only_baseline_picks_up_sql_public_network_access_builtins" {
  command = plan

  assert {
    condition = alltrue([
      for k in ["sql_database_disable_public_network_access", "sql_managed_instance_disable_public_network_access"] :
      contains(keys(local.poc_set_definitions["compeer-private-only-connectivity"].policy_definition_references), k)
    ])
    error_message = "opting into include_builtin_baseline should add the SQL public-network-access builtins to the private-only initiative"
  }
  assert {
    condition     = length(local.poc_set_definitions["compeer-private-only-connectivity"].policy_definition_references) == 4
    error_message = "initiative should have its original 2 custom rules plus the 2 new SQL builtin refs"
  }
}
