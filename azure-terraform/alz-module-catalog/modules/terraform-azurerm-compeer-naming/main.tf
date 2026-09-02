# =============================================================================
# Codified implementation of the target Landing Zone naming standard
# (design doc Appendix F / Section 10.4). ONE explicit pattern per resource
# type - the token order deliberately differs between rows, so this is not a
# single generic formula.
#
# Rows marked ADAPTED are not verbatim in Appendix F - they follow the closest
# relative in the table (per the standard owner's instruction to adapt anything
# not listed to a closely related resource).
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
    # ---- Management groups (fixed tokens; scoped ones need `domain`) ----
    # `domain` carries the node token for every non-fixed MG: a platform child
    # (security, identity, management, connectivity), a workload domain
    # (internal-apps, external-apps, regulated-apps, shared-services), sandbox
    # or decommissioned children, etc. `mg` = <domain>-mg, `mg_environment` =
    # <domain>-<env>-mg.
    mg_enterprise     = "compeer-enterprise-mg"
    mg_platform       = "platform-mg"
    mg_workloads      = "workloads-mg"
    mg_sandbox        = "sandbox-mg"
    mg_decommissioned = "decommissioned-mg"
    mg                = local.domain == null ? null : "${local.domain}-mg"
    mg_environment    = local.domain == null ? null : "${local.domain}-${local.env}-mg"
    # aliases kept for callers that used the workload-domain names
    mg_workload_domain             = local.domain == null ? null : "${local.domain}-mg"
    mg_workload_domain_environment = local.domain == null ? null : "${local.domain}-${local.env}-mg"

    # ---- Subscriptions ----
    subscription_platform     = "sub-platform-${local.env}-${local.region}"
    subscription_identity     = "sub-identity-${local.env}-${local.region}"
    subscription_connectivity = "sub-connectivity-${local.env}-${local.region}"
    subscription_management   = "sub-management-${local.env}-${local.region}"
    subscription_workload     = local.wl_name == null ? null : "sub-workload-${local.wl_name}-${local.env}-${local.region}"
    # ADAPTED: generic scoped subscription (security, sandbox-ops, decommissioned, ...)
    subscription_scoped = local.purpose == null ? null : "sub-${local.purpose}-${local.env}-${local.region}"

    # ---- Networking ----
    hub_vnet    = "platform-${local.region}-${local.env}-hub-vnet"
    shared_vnet = "platform-${local.region}-${local.env}-shared-vnet"
    subnet      = local.purpose == null ? null : "${local.env}-${local.purpose}-subnet"
    nsg         = local.purpose == null ? null : "${local.region}-${local.env}-${local.purpose}-nsg"
    route_table = local.destination == null ? null : "${local.region}-${local.env}-${local.destination}-rt"
    public_ip   = local.resource == null ? null : "${local.region}-${local.env}-${local.resource}-pip"
    # ADAPTED: workload spoke VNet (closest: shared_vnet / hub_vnet)
    workload_vnet = local.domain == null ? null : "${local.domain}-${local.region}-${local.env}-vnet"
    # ADAPTED: NIC / private endpoint (closest: public_ip <region>-<env>-<resource>-*)
    network_interface = local.resource == null ? null : "${local.region}-${local.env}-${local.resource}-nic"
    private_endpoint  = local.resource == null ? null : "${local.region}-${local.env}-${local.resource}-pe"
    # ADAPTED: hub network services (closest: monitor_workspace platform-<region>-<env>-<abbr>)
    nat_gateway          = "platform-${local.region}-${local.env}-natgw"
    route_server         = "platform-${local.region}-${local.env}-rtsrv"
    ddos_protection_plan = "platform-${local.region}-${local.env}-ddos"
    private_dns_resolver = "platform-${local.region}-${local.env}-dnspr"
    bastion              = "platform-${local.region}-${local.env}-bas"

    # ---- Firewall / edge ----
    firewall_vm          = "platform-${local.region}-${local.env}-fw-${local.instance}"
    firewall_ilb         = "platform-${local.region}-${local.env}-fw-ilb"
    expressroute_gateway = "platform-${local.region}-${local.env}-ergw"
    vpn_gateway          = "platform-${local.region}-${local.env}-vpngw"
    cloudflare_connector = "platform-${local.region}-${local.env}-cf-connector-${local.instance}"
    # ADAPTED: hybrid-connectivity sundries (closest: the two gateway rows)
    expressroute_circuit      = "platform-${local.region}-${local.env}-erc"
    expressroute_connection   = "platform-${local.region}-${local.env}-erconn"
    vpn_local_network_gateway = "platform-${local.region}-${local.env}-lng"
    vpn_connection            = "platform-${local.region}-${local.env}-vpnconn"
    # ADAPTED: domain controller VM (closest: firewall_vm platform-<region>-<env>-fw-0<n>)
    domain_controller_vm = "platform-${local.region}-${local.env}-dc-${local.instance}"

    # ---- Observability / recovery ----
    log_analytics_workspace = "${local.region}-${local.env}-loganalytics-workspace"
    monitor_workspace       = "platform-${local.region}-${local.env}-monitor"
    recovery_services_vault = "platform-${local.region}-${local.env}-rsv"
    # ADAPTED: (closest: monitor_workspace / recovery_services_vault)
    automation_account = "platform-${local.region}-${local.env}-aa"
    action_group       = "platform-${local.region}-${local.env}-ag"

    # ---- Key Vault / Resource Group ----
    key_vault               = local.appcode == null ? null : "${local.appcode}-${local.region}-${local.env}-vault"
    platform_resource_group = "platform-${local.region}-${local.env}-rg"
    # ADAPTED: per-capability platform RG (F has one platform RG row; `purpose`
    # carries the capability: connectivity, management, identity, hybrid, ...)
    resource_group = local.purpose == null ? "platform-${local.region}-${local.env}-rg" : "platform-${local.region}-${local.env}-${local.purpose}-rg"
    # ADAPTED: workload spoke RG (closest: mg_environment <domain>-<env>-mg)
    workload_resource_group = local.domain == null ? null : "${local.domain}-${local.env}-rg"
    # ADAPTED: no-separator storage account (<=24, lower). Needs `purpose`.
    storage_account = local.purpose == null ? null : substr(lower(replace("st${local.purpose}${local.region}${local.env}", "-", "")), 0, 24)
    # ADAPTED: user-assigned identity (closest: key_vault <appcode>-<region>-<env>-*)
    user_assigned_identity = local.purpose == null ? null : "${local.purpose}-${local.region}-${local.env}-id"

    # ---- Policy ----
    policy_initiative = (local.domain == null || local.purpose == null) ? null : "initiative-${local.domain}-${local.purpose}"
    policy_assignment = (local.policy == null || local.scope == null) ? null : "assign-${local.policy}-${local.scope}"

    # ---- Entra ID ----
    entra_security_group = (local.entra_dom == null || local.entra_role == null) ? null : "AZ-${local.entra_dom}-${local.entra_role}"

    # ---- Private DNS ----
    private_dns_zone = local.domain == null ? null : "${local.domain}-pdns"
  }
}
