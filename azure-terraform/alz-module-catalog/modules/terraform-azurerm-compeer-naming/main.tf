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

  # Short forms for the length-constrained rows (Key Vault 24, storage 24).
  # Extend only via a versioned change.
  abbr = {
    management                = "mgmt"
    connectivity              = "conn"
    identity                  = "id"
    "hybrid-connectivity"     = "hyb"
    hybrid                    = "hyb"
    "directory-services"      = "ds"
    governance                = "gov"
    policy                    = "pol"
    "shared-services"         = "shared"
    "internal-apps"           = "intapps"
    "external-apps"           = "extapps"
    "regulated-apps"          = "regapps"
    "cloudflare-connectors"   = "cfc"
    "subscription-onboarding" = "subonb"
    "network-peering"         = "peer"
    "palo-alto"               = "pan"
    platform                  = "plat"
  }

  # Normalised tokens. Lowercase + trim everywhere the standard is lowercase;
  # Entra group tokens keep their required casing.
  region = local.region_codes[lower(trimspace(var.region))]
  env    = lower(trimspace(var.environment))
  scope  = lower(trimspace(var.scope))

  domain       = var.domain == null ? null : lower(trimspace(var.domain))
  appcode      = var.appcode == null ? null : lower(trimspace(var.appcode))
  component    = var.component == null ? null : lower(trimspace(var.component))
  purpose      = var.purpose == null ? null : lower(trimspace(var.purpose))
  destination  = var.destination == null ? null : lower(trimspace(var.destination))
  resource     = var.resource == null ? null : lower(trimspace(var.resource))
  wl_name      = var.name == null ? null : lower(trimspace(var.name))
  policy       = var.policy == null ? null : lower(trimspace(var.policy))
  policy_scope = var.policy_scope == null ? null : lower(trimspace(var.policy_scope))
  instance     = format("%02d", var.instance)
  entra_dom    = var.entra_domain == null ? null : upper(trimspace(var.entra_domain))
  entra_role   = var.entra_role == null ? null : trimspace(var.entra_role)

  # The root discriminator - what makes this root's resources differ from
  # another root's in the same region + environment.
  disc = local.scope == "workload" ? coalesce(local.appcode, local.domain, "workload") : coalesce(local.component, "platform")

  # Short form of the discriminator for the length-constrained rows.
  disc_abbr = lookup(local.abbr, local.disc, substr(replace(local.disc, "-", ""), 0, 10))

  # Common stem for the "<disc>-<region>-<env>" rows.
  stem = local.scope == "workload" ? (
    local.appcode == null ? "${local.domain}-${local.region}-${local.env}" : "${local.domain}-${local.appcode}-${local.region}-${local.env}"
  ) : "platform-${local.region}-${local.env}"

  # Optional global-uniqueness suffix for storage-account names.
  st_suffix = var.storage_uniqueness == "" ? "" : substr(md5(var.storage_uniqueness), 0, 4)

  # ---- Keyed collections: <resource> => { key => name } --------------------
  keyed = {
    key_vault               = { for k in var.key_vault_keys : k => "${local.disc_abbr}-${local.region}-${local.env}-${lower(k)}-kv" }
    storage_account         = { for k in var.storage_account_keys : k => substr(lower(replace("st${local.disc_abbr}${k}${local.region}${local.env}${local.st_suffix}", "-", "")), 0, 24) }
    user_assigned_identity  = { for k in var.user_assigned_identity_keys : k => "${local.disc_abbr}-${local.region}-${local.env}-${lower(k)}-id" }
    nsg                     = { for k in var.nsg_keys : k => "${local.region}-${local.env}-${lower(k)}-nsg" }
    route_table             = { for k in var.route_table_keys : k => "${local.region}-${local.env}-${lower(k)}-rt" }
    public_ip               = { for k in var.public_ip_keys : k => "${local.region}-${local.env}-${lower(k)}-pip" }
    private_endpoint        = { for k in var.private_endpoint_keys : k => "${local.region}-${local.env}-${lower(k)}-pe" }
    network_interface       = { for k in var.network_interface_keys : k => "${local.region}-${local.env}-${lower(k)}-nic" }
    load_balancer           = { for k in var.load_balancer_keys : k => "${local.stem}-${lower(k)}-ilb" }
    virtual_machine         = { for k in var.virtual_machine_keys : k => "${local.stem}-${lower(k)}" }
    disk                    = { for k in var.disk_keys : k => "${local.region}-${local.env}-${lower(k)}-disk" }
    recovery_services_vault = { for k in var.recovery_services_vault_keys : k => "${local.stem}-${lower(k)}-rsv" }
    subnet                  = { for k in var.subnet_keys : k => "${local.env}-${lower(k)}-subnet" }
  }

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
    firewall_vm  = "platform-${local.region}-${local.env}-fw-${local.instance}"
    firewall_ilb = "platform-${local.region}-${local.env}-fw-ilb"
    # ADAPTED: internal load balancer, keyed (closest: firewall_ilb). Needs `purpose`.
    load_balancer        = local.purpose == null ? null : "platform-${local.region}-${local.env}-${local.purpose}-ilb"
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
    # Scope-aware resource group:
    #   workload            -> <stem>-rg  (<domain>[-<appcode>]-<region>-<env>-rg)
    #   platform + component -> platform-<region>-<env>-<component>-rg
    #   platform + purpose   -> platform-<region>-<env>-<purpose>-rg  (legacy)
    #   platform (bare)      -> platform-<region>-<env>-rg
    resource_group = (
      local.scope == "workload" ? "${local.stem}-rg" :
      local.component != null ? "platform-${local.region}-${local.env}-${local.component}-rg" :
      local.purpose != null ? "platform-${local.region}-${local.env}-${local.purpose}-rg" :
      "platform-${local.region}-${local.env}-rg"
    )
    # ADAPTED: workload spoke RG (closest: mg_environment <domain>-<env>-mg)
    workload_resource_group = local.domain == null ? null : "${local.domain}-${local.env}-rg"
    # ADAPTED: no-separator storage account (<=24, lower). Legacy single-token.
    storage_account = local.purpose == null ? null : substr(lower(replace("st${local.purpose}${local.region}${local.env}", "-", "")), 0, 24)
    # ADAPTED: user-assigned identity (closest: key_vault <appcode>-<region>-<env>-*)
    user_assigned_identity = local.purpose == null ? null : "${local.purpose}-${local.region}-${local.env}-id"

    # ---- Policy ----
    policy_initiative = (local.domain == null || local.purpose == null) ? null : "initiative-${local.domain}-${local.purpose}"
    policy_assignment = (local.policy == null || local.policy_scope == null) ? null : "assign-${local.policy}-${local.policy_scope}"

    # ---- Entra ID ----
    entra_security_group = (local.entra_dom == null || local.entra_role == null) ? null : "AZ-${local.entra_dom}-${local.entra_role}"

    # ---- Private DNS ----
    private_dns_zone = local.domain == null ? null : "${local.domain}-pdns"
  }
}
