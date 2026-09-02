# =============================================================================
# Codified implementation of the target Landing Zone naming standard
# (design doc Appendix F / Section 10.4). ONE explicit pattern per resource
# type - the token order deliberately differs between rows, so this is not a
# single generic formula.
#
# Pure utility: no providers, no resources, no data sources. It only computes
# strings and validates them. Resource ownership and lifecycle stay entirely
# with the consuming modules.
#
# Any change that alters an ALREADY-PUBLISHED name is a BREAKING change (it can
# force resource replacement downstream) - bump the module major version.
# =============================================================================

locals {
  # Approved Azure region -> short code. Extend only via a versioned change.
  region_codes = {
    centralus      = "cus"
    eastus         = "eus"
    eastus2        = "eus2"
    westus         = "wus"
    westus2        = "wus2"
    westus3        = "wus3"
    southcentralus = "scus"
    northcentralus = "ncus"
    westcentralus  = "wcus"
    canadacentral  = "cnc"
    canadaeast     = "cne"
    uksouth        = "uks"
    ukwest         = "ukw"
    westeurope     = "weu"
    northeurope    = "neu"
  }

  # Normalised tokens. Lowercase + trim everywhere the standard is lowercase;
  # Entra group tokens keep their required casing.
  region = local.region_codes[lower(trimspace(var.region))]
  env    = lower(trimspace(var.environment))

  domain      = var.domain == null ? null : lower(trimspace(var.domain))
  purpose     = var.purpose == null ? null : lower(trimspace(var.purpose))
  destination = var.destination == null ? null : lower(trimspace(var.destination))
  resource    = var.resource == null ? null : lower(trimspace(var.resource))
  appcode     = var.appcode == null ? null : lower(trimspace(var.appcode))
  wl_name     = var.name == null ? null : lower(trimspace(var.name))
  policy      = var.policy == null ? null : lower(trimspace(var.policy))
  scope       = var.scope == null ? null : lower(trimspace(var.scope))
  instance    = format("%02d", var.instance)
  entra_dom   = var.entra_domain == null ? null : upper(trimspace(var.entra_domain))
  entra_role  = var.entra_role == null ? null : trimspace(var.entra_role)

  names = {
    # ---- Management groups (fixed tokens; domain-scoped ones need `domain`) ----
    mg_enterprise                  = "compeer-enterprise-mg"
    mg_platform                    = "platform-mg"
    mg_workloads                   = "workloads-mg"
    mg_sandbox                     = "sandbox-mg"
    mg_decommissioned              = "decommissioned-mg"
    mg_workload_domain             = local.domain == null ? null : "${local.domain}-mg"
    mg_workload_domain_environment = local.domain == null ? null : "${local.domain}-${local.env}-mg"

    # ---- Subscriptions ----
    subscription_platform     = "sub-platform-${local.env}-${local.region}"
    subscription_identity     = "sub-identity-${local.env}-${local.region}"
    subscription_connectivity = "sub-connectivity-${local.env}-${local.region}"
    subscription_management   = "sub-management-${local.env}-${local.region}"
    subscription_workload     = local.wl_name == null ? null : "sub-workload-${local.wl_name}-${local.env}-${local.region}"

    # ---- Networking ----
    hub_vnet    = "platform-${local.region}-${local.env}-hub-vnet"
    shared_vnet = "platform-${local.region}-${local.env}-shared-vnet"
    subnet      = local.purpose == null ? null : "${local.env}-${local.purpose}-subnet"
    nsg         = local.purpose == null ? null : "${local.region}-${local.env}-${local.purpose}-nsg"
    route_table = local.destination == null ? null : "${local.region}-${local.env}-${local.destination}-rt"
    public_ip   = local.resource == null ? null : "${local.region}-${local.env}-${local.resource}-pip"

    # ---- Firewall / edge ----
    firewall_vm          = "platform-${local.region}-${local.env}-fw-${local.instance}"
    firewall_ilb         = "platform-${local.region}-${local.env}-fw-ilb"
    expressroute_gateway = "platform-${local.region}-${local.env}-ergw"
    vpn_gateway          = "platform-${local.region}-${local.env}-vpngw"
    cloudflare_connector = "platform-${local.region}-${local.env}-cf-connector-${local.instance}"

    # ---- Observability / recovery ----
    log_analytics_workspace = "${local.region}-${local.env}-loganalytics-workspace"
    monitor_workspace       = "platform-${local.region}-${local.env}-monitor"
    recovery_services_vault = "platform-${local.region}-${local.env}-rsv"

    # ---- Key Vault / Resource Group ----
    key_vault               = local.appcode == null ? null : "${local.appcode}-${local.region}-${local.env}-vault"
    platform_resource_group = "platform-${local.region}-${local.env}-rg"

    # ---- Policy ----
    policy_initiative = (local.domain == null || local.purpose == null) ? null : "initiative-${local.domain}-${local.purpose}"
    policy_assignment = (local.policy == null || local.scope == null) ? null : "assign-${local.policy}-${local.scope}"

    # ---- Entra ID ----
    entra_security_group = (local.entra_dom == null || local.entra_role == null) ? null : "AZ-${local.entra_dom}-${local.entra_role}"

    # ---- Private DNS ----
    private_dns_zone = local.domain == null ? null : "${local.domain}-pdns"
  }
}
