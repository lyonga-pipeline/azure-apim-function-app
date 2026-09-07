# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id       -> shared HCP variable set (Terraform category, key: tenant_id)
#   subscription_id -> this workspace's Terraform-category variable in HCP
#
# Resource NAMES are NOT set here either - they come from the naming module
# (naming.tf -> design-doc Appendix F). Add a `name = "..."` to any block below
# ONLY to grandfather an existing resource; otherwise leave it out and the
# standard name is used:
#   resource group            platform-<region>-<env>-management-rg
#   log analytics             <region>-<env>-loganalytics-workspace
#   action group              platform-<region>-<env>-ag
#   key vault (key "platform")  platform-<region>-<env>-vault
#   storage account (key "audit")  staudit<region><env>
#   recovery services vault   platform-<region>-<env>-rsv
#   diagnostic settings       diag-<observed resource>-law
#

location    = "centralus"
environment = "prod"

platform_tags = {
  application         = "alz-platform-management"
  owner               = "Cloud Enablement"
  source_repo         = "ado://Compeer/landing-zone"
  created_on          = "2026-01-01"
  criticality_tier    = "tier-2"
  data_classification = "confidential"
  lifecycle_state     = "active"
  cost_center         = "CC-0000"
  gl_category         = "cloud-infrastructure"
  created_by          = "terraform"
  dr_tier             = "standard"
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
    platform = {
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
    platform = {
      key_vault_key = "platform"
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
    platform = {
      storage_mode_type = "ZoneRedundant"
    }
  }
  recovery_services_vault_diagnostics = {
    platform = {
      recovery_services_vault_key = "platform"
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
  defender_plans   = {}
  security_contact = null
  defender_soc_posture = {
    enabled                       = false
    defender_standard_enabled     = false
    sentinel_enabled              = false
    data_collection_rules_enabled = false
    security_contact_enabled      = false
    notes                         = "Enable after SOC onboarding and cost approval."
  }
}
