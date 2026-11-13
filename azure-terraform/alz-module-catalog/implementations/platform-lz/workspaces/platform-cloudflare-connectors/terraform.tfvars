# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id       -> shared HCP variable set (Terraform category, key: tenant_id)
#   subscription_id -> this workspace's Terraform-category variable in HCP
#   Cloudflare API token -> edge workspace only, NOT this Azure VM workspace.
# Connector runtime credentials are separate tunnel tokens, delivered securely.
#

location                    = "centralus"
environment                 = "prod"
tfe_organization            = "Compeer-Financial-Services"
management_workspace_name   = "platform-management"
connectivity_workspace_name = "platform-connectivity"
windows_image_version       = null # REQUIRED: approved 2022-datacenter-g2 version before enabling.

platform_tags = {
  application = "alz-platform-cloudflare-connectors"
  # Same short code the naming module's abbr map uses for this component
  # (cloudflare-connectors -> cfc), so the tag matches the actual name prefix.
  appcode     = "cfc"
  owner       = "Cloud Enablement"
  source_repo = "ado://Compeer/landing-zone"
  # created_on intentionally NOT set here - this workspace's root main.tf
  # owns it via a time_static resource (computed once on first apply,
  # stable across every later plan) and supersedes any value set here.
  # Platform tier-0: foundational enterprise/platform service (enterprise
  # integration backbone) required for other systems.
  criticality_tier    = "tier-0"
  data_classification = "confidential"
  lifecycle_state     = "active"
  cost_center         = "CC-0000"
  gl_category         = "cloud-infrastructure"
  # optional / conditional - set where you have a value
  # application_component = "..."
  # modified_on           = "2026-01-01"
  # created_by intentionally omitted - defaults to "Terraform" now (accurate:
  # this workspace IS how the resource gets created), replacing the old
  # additional_tags workaround below.
  # dr_tier: "standard" isn't one of the doc's four values (gold/silver/
  # bronze/none) and would fail the new validation. Read as "silver" - this
  # is my inference, not a confirmed decision; get this confirmed with
  # whoever owns the actual DR posture.
  dr_tier = "silver"
  # expiration_date      = "2026-12-31"   # sandbox / temporary / POC only
}

# PHASE 2: existing hub producers, never new VNets. Add another map entry for a
# second hub and change only the relevant connectors' hub_key/subnet_key.
# Producers must share NON-SENSITIVE hub_virtual_network_id and subnet_ids.
hub_workspaces = {
  primary = {
    organization = "Compeer-Financial-Services"
    workspace    = "platform-connectivity" # Confirm the deployed HCP workspace name.
  }
  # secondary = { organization = "Compeer-Financial-Services", workspace = "REPLACE_WITH_SECOND_HUB_WORKSPACE" }
}

cloudflare_connectors = {
  enabled                 = false
  require_windows_runtime = true

  resource_group = {}

  # PHASE 2: supply the approved join account/OU and sensitive
  # domain_join_passwords["connector-domain-join"] in HCP before enabling.
  common_domain_join = {
    domain       = "agstar.local"
    username     = "REPLACE_WITH_APPROVED_DOMAIN_JOIN_UPN"
    password_key = "connector-domain-join"
    ou_path      = "" # Empty uses the domain default; set an approved OU where required.
  }

  # PHASE 2: Windows 2022 Datacenter Gen2. IPs/names follow the supplied network
  # document; confirm reservations in each selected hub before enabling.
  # Pin source_image_reference.version to an approved Azure image release if required.
  connectors = {
    np01 = {
      os_type                       = "Windows", name = "cus-np-cft-01", computer_name = "cus-np-cft-01", nic_name = "cus-np-cft-01-nic"
      hub_key                       = "primary", subnet_key = "prod-cftagent-subnet"
      vm_size                       = "Standard_D4s_v5", zone = "1"
      private_ip_address_allocation = "Static", private_ip_address = "10.102.3.4"
      identity                      = { type = "SystemAssigned" }
      os_disk                       = { storage_account_type = "StandardSSD_LRS" }
      extensions                    = { network_watcher = { publisher = "Microsoft.Azure.NetworkWatcher", type = "NetworkWatcherAgentWindows", type_handler_version = "1.4" } }
    }
    np02 = {
      os_type                       = "Windows", name = "cus-np-cft-02", computer_name = "cus-np-cft-02", nic_name = "cus-np-cft-02-nic"
      hub_key                       = "primary", subnet_key = "prod-cftagent-subnet"
      vm_size                       = "Standard_D4s_v5", zone = "2"
      private_ip_address_allocation = "Static", private_ip_address = "10.102.3.5"
      identity                      = { type = "SystemAssigned" }
      os_disk                       = { storage_account_type = "StandardSSD_LRS" }
      extensions                    = { network_watcher = { publisher = "Microsoft.Azure.NetworkWatcher", type = "NetworkWatcherAgentWindows", type_handler_version = "1.4" } }
    }
    prod01 = {
      os_type                       = "Windows", name = "cus-prod-cft-01", computer_name = "cus-prod-cft-01", nic_name = "cus-prod-cft-01-nic"
      hub_key                       = "primary", subnet_key = "prod-cftagent-subnet"
      vm_size                       = "Standard_D4s_v5", zone = "1"
      private_ip_address_allocation = "Static", private_ip_address = "10.102.3.6"
      identity                      = { type = "SystemAssigned" }
      os_disk                       = { storage_account_type = "StandardSSD_LRS" }
      extensions                    = { network_watcher = { publisher = "Microsoft.Azure.NetworkWatcher", type = "NetworkWatcherAgentWindows", type_handler_version = "1.4" } }
    }
    prod02 = {
      os_type                       = "Windows", name = "cus-prod-cft-02", computer_name = "cus-prod-cft-02", nic_name = "cus-prod-cft-02-nic"
      hub_key                       = "primary", subnet_key = "prod-cftagent-subnet"
      vm_size                       = "Standard_D4s_v5", zone = "2"
      private_ip_address_allocation = "Static", private_ip_address = "10.102.3.7"
      identity                      = { type = "SystemAssigned" }
      os_disk                       = { storage_account_type = "StandardSSD_LRS" }
      extensions                    = { network_watcher = { publisher = "Microsoft.Azure.NetworkWatcher", type = "NetworkWatcherAgentWindows", type_handler_version = "1.4" } }
    }
  }

  # Required per VM before enabled=true. Reuse the nonprod secret for np01/np02;
  # use a DIFFERENT prod tunnel secret for prod01/prod02. Values below are
  # references to runtime TOKENS, not raw tunnel secrets or the API token.
  windows_bootstrap = {
    # np01 = {
    #   cloudflared_version = "REPLACE_WITH_APPROVED_RELEASE_AT_LEAST_2025.4.0"
    #   binary_sha256       = "REPLACE_WITH_VERIFIED_64_HEX_SHA256"
    #   key_vault_id        = "REPLACE_WITH_EXISTING_RBAC_KEY_VAULT_RESOURCE_ID"
    #   key_vault_uri       = "https://REPLACE_WITH_VAULT_NAME.vault.azure.net"
    #   token_secret_name   = "cloudflare-nonprod-token"
    #   rollout_revision    = "initial-np01"
    # }
    # Add np02, prod01 and prod02 with the same fields and correct tier secrets.
  }

  operational_contracts = {
    connector_runtime = {
      enabled              = false
      implementation_state = "contract-only"
      required_controls    = ["Palo Alto connector-to-origin policy", "external application authorization tests", "two replicas per tier"]
      notes                = "Windows bootstrap verifies local tunnel readiness; network, security, monitoring and external application acceptance are separate gates."
    }
  }
}

admin_passwords              = {}
custom_data_by_key           = {}
extension_protected_settings = {}

# =============================================================================
# PHASE 2 ADDITIONS - existing configuration above is intentionally retained.
# Optional phase2_* inputs default empty. Use phase2.tfvars.example as the
# engineering reference; merge only its NEW top-level inputs after approval.
# Do not replace this workspace's existing management/policy/VM object.
# See implementations/phase2/ENGINEERING-HANDOFF.md for resource ownership.
# =============================================================================
