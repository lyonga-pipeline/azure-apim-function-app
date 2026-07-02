location    = "eastus"
environment = "np"

platform_tags = {
  application         = "landing-zone-identity"
  business_owner      = "Cloud Enablement"
  source_repo         = "ado://Compeer/azure-cloud"
  terraform_workspace = "lz-platform-identity-np"
  recovery_tier       = "standard"
  cost_center         = "cloud-platform"
  data_classification = "internal"
  compliance_boundary = "finserv"
  additional_tags = {
    deployment_model = "net-new-lz"
  }
}

resource_group = {
  name = "rg-lz-platform-identity-np"
}

platform_identities = {
  deployment = {
    name = "id-lz-deployment-np"
  }
  diagnostics = {
    name = "id-lz-diagnostics-np"
  }
}

key_vault = {
  name                       = "kv-lz-platform-np-001"
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  contacts = {
    cloudops = {
      email = "cloudops@compeer.example"
      name  = "Cloud Operations"
    }
  }
}

identity_role_assignments = {
  diagnostics_secrets_user = {
    identity_key         = "diagnostics"
    role_definition_name = "Key Vault Secrets User"
  }
}

key_vault_private_endpoint = null

# Optional: set this to the platform-management output
# `log_analytics_workspace_id` to enable Key Vault diagnostics. Leaving it unset
# lets this stack run before the shared monitoring workspace is wired in HCP.
# log_analytics_workspace_id = "/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.OperationalInsights/workspaces/<workspace-name>"

management_locks = {
  identity_rg = {
    name       = "lock-rg-lz-platform-identity-np"
    scope_key  = "resource_group"
    lock_level = "CanNotDelete"
    notes      = "Protects shared platform identities and key vault resources."
  }
  platform_key_vault = {
    name       = "lock-kv-lz-platform-np-001"
    scope_key  = "key_vault"
    lock_level = "CanNotDelete"
    notes      = "Protects platform key vault from accidental deletion."
  }
}
