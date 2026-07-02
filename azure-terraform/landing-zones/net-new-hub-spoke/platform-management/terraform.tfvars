location    = "eastus"
environment = "np"

platform_tags = {
  application         = "landing-zone-management"
  business_owner      = "Cloud Enablement"
  source_repo         = "ado://Compeer/azure-cloud"
  terraform_workspace = "lz-platform-management-np"
  recovery_tier       = "standard"
  cost_center         = "cloud-platform"
  data_classification = "internal"
  compliance_boundary = "finserv"
  additional_tags = {
    deployment_model = "net-new-lz"
  }
}

resource_group = {
  name = "rg-lz-platform-management-np"
}

log_analytics = {
  name              = "law-lz-platform-np"
  retention_in_days = 90
}

action_group = {
  name       = "ag-lz-cloudops-np"
  short_name = "lzopsnp"
  receivers = {
    email = {
      cloudops = {
        email_address = "cloudops@compeer.example"
      }
    }
  }
}

# Keep resource provider registrations unmanaged during short smoke tests.
# Most test subscriptions already have common providers registered, and
# pre-existing registrations must be imported before Terraform can manage them.
resource_provider_registrations = {}

# To promote the enterprise baseline, import any pre-existing registrations
# first, then uncomment and manage the approved provider list.
#
# resource_provider_registrations = {
#   "Microsoft.Authorization"       = {}
#   "Microsoft.CostManagement"      = {}
#   "Microsoft.EventGrid"           = {}
#   "microsoft.insights"            = {}
#   "Microsoft.KeyVault"            = {}
#   "Microsoft.ManagedIdentity"     = {}
#   "Microsoft.Network"             = {}
#   "Microsoft.OperationalInsights" = {}
#   "Microsoft.PolicyInsights"      = {}
#   "Microsoft.Security"            = {}
#   "Microsoft.Storage"             = {}
#   "Microsoft.Web"                 = {}
# }

role_assignments = {}

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

entra_diagnostic_settings = {
  name = "diag-entra-to-law"
  logs = {
    audit_logs = {
      category = "AuditLogs"
    }
    sign_in_logs = {
      category = "SignInLogs"
    }
    non_interactive_sign_in_logs = {
      category = "NonInteractiveUserSignInLogs"
    }
    service_principal_sign_in_logs = {
      category = "ServicePrincipalSignInLogs"
    }
    managed_identity_sign_in_logs = {
      category = "ManagedIdentitySignInLogs"
    }
    provisioning_logs = {
      category = "ProvisioningLogs"
    }
  }
}

subscription_budgets = {
  platform_management_monthly = {
    amount     = 15000
    time_grain = "Monthly"
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

management_locks = {
  management_rg = {
    name       = "lock-rg-lz-platform-management-np"
    scope_key  = "resource_group"
    lock_level = "CanNotDelete"
    notes      = "Protects central monitoring and alerting resources from accidental deletion."
  }
  log_analytics = {
    name       = "lock-law-lz-platform-np"
    scope_key  = "log_analytics"
    lock_level = "CanNotDelete"
    notes      = "Protects centralized audit and operations logs."
  }
}

# Keep Defender for Cloud paid plans disabled for short landing-zone smoke tests.
# To test or promote the enterprise security baseline, uncomment the Standard
# plan map below and rerun this workspace after cost approval.
defender_plans = {}

# defender_plans = {
#   servers = {
#     resource_type = "VirtualMachines"
#     tier          = "Standard"
#   }
#   app_services = {
#     resource_type = "AppServices"
#     tier          = "Standard"
#   }
#   storage = {
#     resource_type = "StorageAccounts"
#     tier          = "Standard"
#   }
#   key_vaults = {
#     resource_type = "KeyVaults"
#     tier          = "Standard"
#   }
#   sql_servers = {
#     resource_type = "SqlServers"
#     tier          = "Standard"
#   }
#   arm = {
#     resource_type = "Arm"
#     tier          = "Standard"
#   }
# }

# Keep Defender for Cloud contact and subscription-wide security settings
# unmanaged during short smoke tests. These settings often already exist in a
# subscription and must be imported before Terraform can manage them.
security_contact         = null
security_center_settings = {}

# To promote the enterprise security baseline, import any pre-existing settings
# first, then uncomment and manage these values.
#
# security_contact = {
#   email               = "cloudsecurity@compeer.example"
#   phone               = "+15555550100"
#   alert_notifications = true
#   alerts_to_admins    = true
# }
#
# security_center_settings = {
#   MCAS = {
#     enabled = true
#   }
#   WDATP = {
#     enabled = true
#   }
# }
