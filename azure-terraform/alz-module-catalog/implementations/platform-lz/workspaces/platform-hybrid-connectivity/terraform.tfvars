# Deployable tfvars for this workspace.
#
# Auth is NOT set here:
#   tenant_id       -> shared HCP variable set (Terraform category, key: tenant_id)
#   subscription_id -> this workspace's Terraform-category variable in HCP
# The azurerm provider reads both from those Terraform variables.
#

location                    = "centralus"
environment                 = "prod"
tfe_organization            = "Compeer-Financial-Services"
connectivity_workspace_name = "platform-connectivity"

platform_tags = {
  application = "alz-platform-hybrid-connectivity"
  # Same short code the naming module's abbr map uses for this component
  # (hybrid / hybrid-connectivity -> hyb), so the tag matches the actual
  # name prefix.
  appcode     = "hyb"
  owner       = "Cloud Enablement"
  source_repo = "ado://Compeer/landing-zone"
  # created_on intentionally NOT set here - this workspace's root main.tf
  # owns it via a time_static resource (computed once on first apply,
  # stable across every later plan) and supersedes any value set here.
  # Platform tier-0: foundational enterprise/platform service (ExpressRoute/
  # VPN networking backbone) required for other systems.
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

hybrid_connectivity = {
  enabled        = true
  resource_group = {}
  expressroute_posture = {
    enabled                   = false
    onpremises_required       = true
    provider_design_reference = null
    bgp_and_routing_approved  = false
    cutover_window_approved   = false
    notes                     = "Enable after carrier/provider details are approved."
  }
  expressroute_circuits    = {}
  gateway_public_ips       = {}
  expressroute_gateway     = null
  expressroute_connections = {}

  vpn_posture = {
    enabled                      = false
    backup_required              = true
    design_reference             = null
    bgp_and_routing_approved     = false
    shared_key_handling_approved = false
    failover_test_approved       = false
    notes                        = "Enable after VPN peer details, PSK handling, routing, and failover testing are approved."
  }
  vpn_gateway_public_ips = {}
  vpn_gateway            = null
  local_network_gateways = {}
  vpn_connections        = {}

  # Azure Route Server lives in the hybrid-connectivity resource group per the
  # 2026-10-01 hub update. The subnet is owned by platform-connectivity and is
  # resolved from that workspace's published subnet_ids output.
  route_server_public_ips = {
    primary = {
      name  = "platform-cus-prod-rs-pip"
      zones = ["1", "2", "3"]
    }
  }
  route_servers = {
    primary = {
      name                             = "platform-cus-prod-rs"
      subnet_key                       = "RouteServerSubnet"
      public_ip_key                    = "primary"
      branch_to_branch_traffic_enabled = true # Confirm with CDW before production traffic cutover.
    }
  }

  # Network engineer request: managed identity + RBAC for VPN gateway
  # certificate management. Standalone scaffolding - not gated behind
  # vpn_posture.enabled, since it's low-cost prep infrastructure (an identity
  # + role assignments, not a paid gateway) that can exist ahead of the VPN
  # posture being fully approved.
  #
  # Placement decision (resource-placement sheet, security-mg /
  # platform-cus-prod-keyvault-rg): certificates live in the shared platform
  # Key Vault (platform-cus-prod-vault, owned by platform-identity-security),
  # not a dedicated vault here - this replaces the earlier standalone
  # "kv-vpn-cert-prod" vault + private endpoint. key_vault_id is NOT set here
  # - this workspace's root main.tf auto-resolves it from
  # platform-identity-security's published key_vault_id output; enabled =
  # true with that workspace not yet deployed is a graceful no-op (the
  # identity/RBAC simply appear once it exists), not an error.
  vpn_certificate_key_vault = {
    enabled = true
  }
}
