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
#   key vault (key "main")         mgmt-cus-prod-main-kv       (keep KV keys <= 7 chars)
#   storage account (key "audit")  stmgmtauditcusprod
#   recovery services vault (main) platform-cus-prod-main-rsv
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
  # observability, Sentinel/Defender, backup) required for other systems.
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
    retention_in_days = 365
    daily_quota_gb    = 5
  }
  action_group = {
    short_name = "platops"
    receivers  = {}
  }
  platform_storage_accounts = {
    audit = {
      account_replication_type          = "ZRS"
      public_network_access_enabled     = false
      shared_access_key_enabled         = false
      infrastructure_encryption_enabled = true
      default_to_oauth_authentication   = true
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
  platform_key_vaults = {
    main = {
      sku_name                      = "standard"
      rbac_authorization_enabled    = true
      purge_protection_enabled      = true
      public_network_access_enabled = false
      network_acls = {
        bypass         = "AzureServices"
        default_action = "Deny"
      }
    }
  }
  platform_key_vault_diagnostics = {
    main = {
      key_vault_key = "main"
      logs = {
        audit = { category = "AuditEvent" }
      }
      metrics = {
        all = { category = "AllMetrics" }
      }
    }
  }
  platform_key_vault_private_endpoints = {}
  recovery_services_vaults = {
    main = {
      # Flipped back to the module's own default (GeoRedundant) from
      # ZoneRedundant: backups are the one asset a region-level rebuild-from-
      # IaC DR story can't replace - a zone-redundant-only vault goes down
      # with a full regional outage, right when backups matter most. Nothing
      # is deployed yet, so this is a zero-cost, zero-migration correction.
      storage_mode_type = "GeoRedundant"
    }
  }
  recovery_services_vault_diagnostics = {
    main = {
      recovery_services_vault_key = "main"
      logs = {
        all = { category_group = "allLogs" }
      }
      metrics = {
        all = { category = "AllMetrics" }
      }
    }
  }
  data_collection_endpoints         = {}
  data_collection_rules             = {}
  data_collection_rule_associations = {}
  sentinel = {
    enabled = false
    approved_data_connectors = {
      activity_log = {
        connector_type = "AzureActivity"
        enabled        = false
      }
      defender_for_cloud = {
        connector_type = "MicrosoftDefenderForCloud"
        enabled        = false
      }
      entra_id = {
        connector_type = "MicrosoftEntraID"
        enabled        = false
      }
    }
  }
  # Defender for Cloud - approved pricing decision: Servers Plan 1 (P1) only.
  # P1 covers vulnerability assessment, just-in-time VM access, and adaptive
  # network hardening; it does NOT include Microsoft Defender for Endpoint
  # (that's P2 - a separate, larger cost decision, not approved here). Add
  # further resource_type entries (SqlServers, StorageAccounts, KeyVaults,
  # AppServices, Containers, Arm, Dns, CosmosDbs, ...) only after the same
  # kind of explicit per-plan pricing-tier approval - each is its own cost
  # line, not a bundle.
  defender_plans = {
    virtual_machines = {
      resource_type = "VirtualMachines"
      tier          = "Standard"
      subplan       = "P1"
    }
  }
  security_contact = null
  defender_soc_posture = {
    enabled                       = true
    defender_standard_enabled     = true
    sentinel_enabled              = false
    data_collection_rules_enabled = false
    security_contact_enabled      = false
    notes                         = "Defender for Cloud Servers P1 approved and enabled. Security contact, Sentinel, and DCR-based SOC integration remain pending separate SOC onboarding and cost approval."
  }
}
