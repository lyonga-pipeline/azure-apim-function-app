# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id       -> shared HCP variable set (Terraform category, key: tenant_id)
#   subscription_id -> this workspace's Terraform-category variable in HCP
#
# Resource NAMES are NOT set here - the pattern's naming module produces them
# from region + environment + component "management" + the map key you choose.
# Add `name = "..."` to a block ONLY to grandfather an existing resource.
# Standard names for this root (component = management, cus/prod):
#   resource group                 platform-cus-prod-management-rg
#   log analytics                  cus-prod-loganalytics-workspace
#   action group                   platform-cus-prod-ag
#   storage account (key "audit")  stmgmtauditcusprod
#   diagnostic settings            diag-<observed resource name>-law
#

location    = "centralus"
environment = "prod"

platform_tags = {
  application = "alz-platform-management"
  # Same short code the naming module's abbr map uses for this component
  # (management -> mgmt), so the tag matches the actual name prefix.
  appcode     = "mgmt"
  owner       = "Cloud Enablement"
  source_repo = "ado://Compeer/landing-zone"
  # created_on intentionally NOT set here - this workspace's root main.tf
  # owns it via a time_static resource (computed once on first apply,
  # stable across every later plan) and supersedes any value set here.
  # Platform tier-0: foundational enterprise/platform service (shared
  # observability, Sentinel/Defender, diagnostics/archive storage, budgets)
  # required for other systems.
  criticality_tier    = "tier-0"
  data_classification = "confidential"
  lifecycle_state     = "active"
  cost_center         = "CC-0000"
  gl_category         = "cloud-infrastructure"
  # created_by intentionally omitted - defaults to "Terraform" now, which is
  # accurate (this workspace IS how the resource gets created) and replaces
  # the old lowercase "terraform" override.
  # dr_tier: "standard" isn't one of the doc's four values (gold/silver/
  # bronze/none) and would fail the new validation. Read as "silver" -
  # shared platform/observability infra needing formal DR with less
  # aggressive RTO/RPO than a member-facing system - but this is my
  # inference, not a confirmed decision; get this confirmed with whoever
  # owns the actual DR posture for this workspace.
  dr_tier = "silver"
}

management = {
  enabled        = true
  resource_group = {}
  log_analytics = {
    # Client security lead direction: 90 days analytics retention with
    # long-term retention carrying applicable security tables to 1.5 years
    # total. No hard daily cap here; use the subscription budget below for
    # cost guardrails so security telemetry does not silently stop ingesting.
    retention_in_days                       = 90
    daily_quota_gb                          = -1
    local_authentication_disabled           = true
    internet_ingestion_enabled              = true
    internet_query_enabled                  = true
    allow_resource_only_permissions         = true
    immediate_data_purge_on_30_days_enabled = false
  }
  # Security lead response: Compeer requires 1.5 years total security-log
  # retention, with 90 days available for analytics. Manage only the tables
  # this LZ is currently configured to populate; Entra tables (AuditLogs,
  # SigninLogs) stay out until tenant-level Entra diagnostics are approved.
  log_analytics_tables = {
    AzureActivity = {
      retention_in_days       = 90
      total_retention_in_days = 548
    }
    CommonSecurityLog = {
      retention_in_days       = 90
      total_retention_in_days = 548
    }
    SecurityAlert = {
      retention_in_days       = 90
      total_retention_in_days = 548
    }
    SecurityRecommendation = {
      retention_in_days       = 90
      total_retention_in_days = 548
    }
  }
  action_group = {
    short_name = "platops"
    receivers = {
      email = {
        cloud_enablement = {
          email_address           = "Compeer-DTICloudEnablementTeam@compeer.com"
          use_common_alert_schema = true
        }
      }
    }
  }
  platform_storage_accounts = {
    audit = {
      account_replication_type          = "ZRS"
      public_network_access_enabled     = false
      shared_access_key_enabled         = false
      infrastructure_encryption_enabled = true
      default_to_oauth_authentication   = true
      allow_nested_items_to_be_public   = false
      min_tls_version                   = "TLS1_2"
      https_traffic_only_enabled        = true
      cross_tenant_replication_enabled  = false
      network_rules = {
        default_action = "Deny"
        bypass         = ["AzureServices"]
      }
      blob_properties = {
        versioning_enabled              = true
        change_feed_enabled             = true
        change_feed_retention_in_days   = 90
        delete_retention_days           = 35
        container_delete_retention_days = 35
        restore_policy = {
          days = 30
        }
      }
      queue_properties = {
        logging = {
          delete                = true
          read                  = true
          write                 = true
          version               = "1.0"
          retention_policy_days = 30
        }
        hour_metrics = {
          enabled               = true
          version               = "1.0"
          include_apis          = true
          retention_policy_days = 30
        }
        minute_metrics = {
          enabled               = true
          version               = "1.0"
          include_apis          = true
          retention_policy_days = 30
        }
      }
    }
  }
  platform_storage_diagnostics = {
    audit = {
      storage_account_key = "audit"
      metrics = {
        transaction = { category = "Transaction" }
      }
    }
  }
  # Refined placement keeps shared platform Key Vault in security-mg and
  # workload-specific backup vaults in the subscriptions that own protected
  # VMs (identity for DCs, connectivity for firewall VMs if approved). This
  # management workspace intentionally does not create Key Vaults, private
  # endpoints, or Recovery Services vaults.
  data_collection_endpoints         = {}
  data_collection_rules             = {}
  data_collection_rule_associations = {}
  resource_provider_registrations   = {}
  role_assignments                  = {}
  subscription_activity_log_diagnostics = {
    name = "diag-subscription-activity-to-law"
    logs = {
      administrative = {
        category = "Administrative"
      }
      security = {
        category = "Security"
      }
      service_health = {
        category = "ServiceHealth"
      }
      alert = {
        category = "Alert"
      }
      recommendation = {
        category = "Recommendation"
      }
      policy = {
        category = "Policy"
      }
      autoscale = {
        category = "Autoscale"
      }
      resource_health = {
        category = "ResourceHealth"
      }
    }
  }
  # Entra diagnostics are tenant-level Microsoft.AADIAM resources. Keep null
  # until the HCP run identity has tenant-level permission to manage them.
  entra_diagnostic_settings = null
  subscription_budgets = {
    platform_management_monthly = {
      amount     = 15000
      time_grain = "Monthly"
      time_period = {
        start_date = "2026-10-01T00:00:00Z"
      }
      notifications = {
        actual_80 = {
          threshold      = 80
          operator       = "GreaterThan"
          threshold_type = "Actual"
          contact_emails = ["Compeer-DTICloudEnablementTeam@compeer.com"]
        }
        actual_100 = {
          threshold      = 100
          operator       = "GreaterThan"
          threshold_type = "Actual"
          contact_emails = ["Compeer-DTICloudEnablementTeam@compeer.com"]
        }
        forecast_100 = {
          threshold      = 100
          operator       = "GreaterThan"
          threshold_type = "Forecasted"
          contact_emails = ["Compeer-DTICloudEnablementTeam@compeer.com"]
        }
      }
    }
  }
  management_locks = {
    resource_group = {
      name       = "lock-platform-management-rg"
      scope_key  = "resource_group"
      lock_level = "CanNotDelete"
      notes      = "Protects central monitoring, Sentinel, Defender, budgets, and platform archive resources from accidental deletion."
    }
    log_analytics = {
      name       = "lock-platform-log-analytics"
      scope_key  = "log_analytics"
      lock_level = "CanNotDelete"
      notes      = "Protects centralized platform audit and SOC logs."
    }
    audit_storage = {
      name       = "lock-platform-audit-storage"
      scope_key  = "storage_account:audit"
      lock_level = "CanNotDelete"
      notes      = "Protects platform diagnostics and audit storage."
    }
  }
  sentinel = {
    enabled               = true
    include_default_rules = true
    approved_data_connectors = {
      activity_log = {
        connector_type = "AzureActivity"
        enabled        = true
        notes          = "Activity Log is routed by subscription_activity_log_diagnostics."
      }
      defender_for_cloud = {
        connector_type = "MicrosoftDefenderForCloud"
        enabled        = true
      }
      entra_id = {
        connector_type = "MicrosoftEntraID"
        enabled        = false
        notes          = "Enable after tenant-level Entra diagnostic export and SOC validation of AuditLogs/SigninLogs tables."
      }
      threat_intelligence = {
        connector_type = "ThreatIntelligence"
        enabled        = false
        notes          = "Enable after SOC confirms threat-intelligence feed ownership and connector requirements."
      }
      defender_atp = {
        connector_type = "MicrosoftDefenderAdvancedThreatProtection"
        enabled        = false
        notes          = "Enable only after Defender for Endpoint / Defender for Servers P2 decision is approved."
      }
    }
    data_connectors = {
      threat_intelligence = false
      defender_atp        = false
      entra_id            = false
      defender_for_cloud  = true
    }
    # Extra identity/governance rules (new GA, Owner assignment, PIM activation,
    # MG/policy change, password spray) are real KQL examples, but the LZ
    # boundary marks them as Hybrid/future content. Keep them in the pattern
    # example until SOC validates the connected tenant tables and incident
    # workflow; the mandatory deployable baseline is the module's default
    # Palo Alto CEF forwarding-health and critical-threat rules.
    scheduled_alert_rules = {}
  }
  defender_plans = {
    virtual_machines = {
      resource_type = "VirtualMachines"
      tier          = "Standard"
      subplan       = "P1"
    }
    storage_accounts = {
      resource_type = "StorageAccounts"
      tier          = "Standard"
    }
    key_vaults = {
      resource_type = "KeyVaults"
      tier          = "Standard"
    }
    app_services = {
      resource_type = "AppServices"
      tier          = "Standard"
    }
    sql_servers = {
      resource_type = "SqlServers"
      tier          = "Standard"
    }
    containers = {
      resource_type = "Containers"
      tier          = "Standard"
    }
    arm = {
      resource_type = "Arm"
      tier          = "Standard"
    }
  }
  security_contact = {
    email               = "Jordan.West@compeer.com"
    alert_notifications = true
    alerts_to_admins    = true
  }
  security_center_settings = {
    MCAS = {
      enabled = true
    }
  }
  platform_alerts = {
    enabled                = true
    service_health_enabled = true
    service_health_events  = ["Incident", "Maintenance", "Security"]
    service_health_locations = [
      "Global",
      "Central US"
    ]
    metric_alerts = {}
  }
  defender_soc_posture = {
    enabled                       = true
    defender_standard_enabled     = true
    sentinel_enabled              = true
    data_collection_rules_enabled = false
    security_contact_enabled      = true
    notes                         = "Enterprise baseline: new LZ Log Analytics and Sentinel environment, Defender Standard plans, subscription Activity Log export, 90-day analytics plus 1.5-year total retention for active security tables, Defender security contact, Service Health alerting, budget alerts, and protective locks enabled. Entra diagnostic export, ServiceNow/SIR integration, and extra SOC detection content remain owned/approved by Security Operations."
  }
}
