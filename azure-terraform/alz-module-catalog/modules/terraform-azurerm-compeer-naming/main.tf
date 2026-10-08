locals {
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
  kv_token     = lower(trimspace(var.key_vault_name_token))
  entra_dom    = var.entra_domain == null ? null : upper(trimspace(var.entra_domain))
  entra_role   = var.entra_role == null ? null : trimspace(var.entra_role)

  disc           = local.scope == "workload" ? coalesce(local.appcode, local.domain, "workload") : coalesce(local.component, "platform")
  workload_token = coalesce(local.wl_name, local.appcode, local.domain, "MISSING-DOMAIN")

  disc_abbr = var.abbreviation != null ? lower(trimspace(var.abbreviation)) : (
    local.scope == "workload" && local.appcode != null ? local.appcode : lookup(local.abbr, local.disc, null)
  )
  # Keeps collection expressions evaluable while the dedicated check emits the actionable error.
  disc_abbr_rendered = coalesce(local.disc_abbr, "missing")

  # The sentinel allows checks.tf to report a clear missing-domain error.
  stem = local.scope == "workload" ? (
    local.appcode == null ? "${coalesce(local.domain, "MISSING-DOMAIN")}-${local.region}-${local.env}" : "${coalesce(local.domain, "MISSING-DOMAIN")}-${local.appcode}-${local.region}-${local.env}"
  ) : "platform-${local.region}-${local.env}"

  st_suffix = var.storage_uniqueness == "" ? "" : substr(md5(var.storage_uniqueness), 0, 4)

  # v1.1: VNet peering (one name per side) and private DNS zone VNet links.
  vnet_peerings     = { for k, p in var.vnet_peerings : k => "${lower(trimspace(p.local_vnet))}-to-${lower(trimspace(p.remote_vnet))}" }
  private_dns_links = { for v in var.private_dns_link_vnets : v => "${lower(trimspace(v))}-link" }

  # ---- Keyed collections: <resource> => { key => name } --------------------
  keyed = {
    key_vault = { for k in var.key_vault_keys : k => "${local.disc_abbr_rendered}-${local.region}-${local.env}-${replace(lower(trimspace(k)), "_", "-")}" }
    # Reserve the required tail before truncating the caller-controlled token.
    storage_account = {
      for k in var.storage_account_keys : k => "st${local.disc_abbr_rendered}${substr(
        lower(replace(replace(trimspace(k), "-", ""), "_", "")),
        0,
        max(0, 24 - length("st${local.disc_abbr_rendered}${local.region}${local.env}${local.st_suffix}"))
      )}${local.region}${local.env}${local.st_suffix}"
    }
    user_assigned_identity  = { for k in var.user_assigned_identity_keys : k => "${local.disc_abbr_rendered}-${local.region}-${local.env}-${replace(lower(trimspace(k)), "_", "-")}-id" }
    function_app            = { for k in var.function_app_keys : k => "${local.disc_abbr_rendered}-${local.region}-${local.env}-azfn-${format("%02d", tonumber(k))}" }
    nsg                     = { for k in var.nsg_keys : k => "${local.region}-${local.env}-${replace(lower(trimspace(k)), "_", "-")}-nsg" }
    route_table             = { for k in var.route_table_keys : k => "${local.region}-${local.env}-${replace(lower(trimspace(k)), "_", "-")}-rt" }
    public_ip               = { for k in var.public_ip_keys : k => "${local.region}-${local.env}-${replace(lower(trimspace(k)), "_", "-")}-pip" }
    private_endpoint        = { for k in var.private_endpoint_keys : k => "${local.region}-${local.env}-${replace(lower(trimspace(k)), "_", "-")}-pe" }
    network_interface       = { for k in var.network_interface_keys : k => "${local.region}-${local.env}-${replace(lower(trimspace(k)), "_", "-")}-nic" }
    load_balancer           = { for k in var.load_balancer_keys : k => "${local.stem}-${replace(lower(trimspace(k)), "_", "-")}-ilb" }
    virtual_machine         = { for k in var.virtual_machine_keys : k => "${local.stem}-${replace(lower(trimspace(k)), "_", "-")}" }
    disk                    = { for k in var.disk_keys : k => "${local.region}-${local.env}-${replace(lower(trimspace(k)), "_", "-")}-disk" }
    recovery_services_vault = { for k in var.recovery_services_vault_keys : k => "${local.stem}-${replace(lower(trimspace(k)), "_", "-")}-rsv" }
    subnet                  = { for k in var.subnet_keys : k => "${local.env}-${replace(lower(trimspace(k)), "_", "-")}-subnet" }
    # v1.1: purpose-keyed resource groups. Includes the component/stem token
    # (unlike the singular resource_group's own component logic, this must
    # stay collision-safe across DIFFERENT platform roots sharing a key, e.g.
    # "network" in both platform-management and platform-connectivity).
    resource_group = {
      for k in var.resource_group_keys : k => (
        local.scope == "workload" ? "${local.stem}-${replace(lower(trimspace(k)), "_", "-")}-rg" :
        local.component != null ? "platform-${local.region}-${local.env}-${local.component}-${replace(lower(trimspace(k)), "_", "-")}-rg" :
        "platform-${local.region}-${local.env}-${replace(lower(trimspace(k)), "_", "-")}-rg"
      )
    }
  }

  names = {
    # ---- Management groups (fixed tokens; scoped ones need `domain`) ----
    mg_enterprise                  = "compeer-enterprise-mg"
    mg_platform                    = "platform-mg"
    mg_workloads                   = "workloads-mg"
    mg_sandbox                     = "sandbox-mg"
    mg_decommissioned              = "decommissioned-mg"
    mg                             = local.domain == null ? null : "${local.domain}-mg"
    mg_environment                 = local.domain == null ? null : "${local.domain}-${local.env}-mg"
    mg_workload_domain             = local.domain == null ? null : "${local.domain}-mg"
    mg_workload_domain_environment = local.domain == null ? null : "${local.domain}-${local.env}-mg"

    # ---- Subscriptions ----
    subscription_platform     = "sub-platform-${local.env}-${local.region}"
    subscription_identity     = "sub-identity-${local.env}-${local.region}"
    subscription_connectivity = "sub-connectivity-${local.env}-${local.region}"
    subscription_management   = "sub-management-${local.env}-${local.region}"
    subscription_workload     = local.wl_name == null ? null : "sub-workload-${local.wl_name}-${local.env}-${local.region}"
    subscription_scoped       = local.purpose == null ? null : "sub-${local.purpose}-${local.env}-${local.region}"
    # v1.1: first-class security subscription row (equivalent to
    # subscription_scoped with purpose = "security"; kept as its own output
    # for callers that don't otherwise need to set `purpose`).
    subscription_security = "sub-security-${local.env}-${local.region}"

    # ---- Networking ----
    hub_vnet             = "platform-${local.region}-${local.env}-hub-vnet"
    shared_vnet          = "platform-${local.region}-${local.env}-shared-vnet"
    identity_vnet        = "platform-${local.region}-${local.env}-identity-vnet"
    subnet               = local.purpose == null ? null : "${local.env}-${local.purpose}-subnet"
    nsg                  = local.purpose == null ? null : "${local.region}-${local.env}-${local.purpose}-nsg"
    route_table          = local.destination == null ? null : "${local.region}-${local.env}-${local.destination}-rt"
    public_ip            = local.resource == null ? null : "${local.region}-${local.env}-${local.resource}-pip"
    workload_vnet        = local.domain == null ? null : "${local.workload_token}-${local.region}-${local.env}-spoke-vnet"
    network_interface    = local.resource == null ? null : "${local.region}-${local.env}-${local.resource}-nic"
    private_endpoint     = local.resource == null ? null : "${local.region}-${local.env}-${local.resource}-pe"
    nat_gateway          = "platform-${local.region}-${local.env}-natgw"
    route_server         = "platform-${local.region}-${local.env}-rs"
    ddos_protection_plan = "platform-${local.region}-${local.env}-ddos"
    private_dns_resolver = "platform-${local.region}-${local.env}-dnspr"
    bastion              = "platform-${local.region}-${local.env}-bas"

    # ---- Firewall / edge ----
    firewall_vm                = "platform-${local.region}-${local.env}-fw-${local.instance}"
    firewall_ilb               = "platform-${local.region}-${local.env}-fw-ilb"
    load_balancer              = local.purpose == null ? null : "platform-${local.region}-${local.env}-${local.purpose}-ilb"
    expressroute_gateway       = "platform-${local.region}-${local.env}-ergw"
    vpn_gateway                = "platform-${local.region}-${local.env}-vpngw"
    cloudflare_connector       = "platform-${local.region}-${local.env}-cf-connector-${local.instance}"
    expressroute_circuit       = "platform-${local.region}-${local.env}-erc"
    expressroute_connection    = "platform-${local.region}-${local.env}-erconn"
    vpn_local_network_gateway  = "platform-${local.region}-${local.env}-lng"
    vpn_connection             = "platform-${local.region}-${local.env}-vpnconn"
    domain_controller_vm       = "platform-${local.region}-${local.env}-dc-${local.instance}"
    domain_controller_extdc_vm = "platform-${local.region}-${local.env}-extdc-${local.instance}"
    # v1.1: separate, 15-char-safe Windows computer_name for domain
    # controllers (NetBIOS limit) - NOT the same string as the Azure VM
    # resource name above (that has Azure's normal 64-char VM name budget
    # and no reason to be short). "AZR-<region>-<role>-<nn>" with a 3-char
    # role token keeps this <=15 chars in every approved region, including
    # the four-letter ones (eus2, wus2, wus3, scus, ncus, wcus) where a
    # 4-char role token like "ADDS" would overflow.
    domain_controller_computer_name       = "AZR-${upper(local.region)}-ADS-${local.instance}"
    domain_controller_extdc_computer_name = "AZR-${upper(local.region)}-EXD-${local.instance}"

    # ---- Observability / recovery ----
    log_analytics_workspace = "${local.region}-${local.env}-loganalytics-workspace"
    monitor_workspace       = "platform-${local.region}-${local.env}-monitor"
    recovery_services_vault = "platform-${local.region}-${local.env}-rsv"
    automation_account      = "platform-${local.region}-${local.env}-aa"
    action_group            = "platform-${local.region}-${local.env}-ag"

    # ---- Key Vault / resource group ----
    key_vault = (
      local.scope == "workload" ? (local.appcode == null ? null : "${local.appcode}-${local.region}-${local.env}-${local.kv_token}") :
      local.component != null && local.disc_abbr != null ? "${local.disc_abbr}-${local.region}-${local.env}-${local.kv_token}" :
      null
    )
    platform_resource_group = "platform-${local.region}-${local.env}-rg"
    resource_group = (
      local.scope == "workload" ? "${local.stem}-rg" :
      local.component != null ? "platform-${local.region}-${local.env}-${local.component}-rg" :
      local.purpose != null ? "platform-${local.region}-${local.env}-${local.purpose}-rg" :
      "platform-${local.region}-${local.env}-rg"
    )
    workload_resource_group = local.domain == null ? null : "${local.domain}-${local.env}-rg"
    storage_account = local.purpose == null ? null : "st${local.disc_abbr_rendered}${substr(
      lower(replace(replace(local.purpose, "-", ""), "_", "")),
      0,
      max(0, 24 - length("st${local.disc_abbr_rendered}${local.region}${local.env}${local.st_suffix}"))
    )}${local.region}${local.env}${local.st_suffix}"
    user_assigned_identity = local.purpose == null ? null : "${local.purpose}-${local.region}-${local.env}-id"
    function_app           = local.appcode == null ? null : "${local.appcode}-${local.region}-${local.env}-azfn-${local.instance}"

    # ---- Policy ----
    policy_initiative = (local.domain == null || local.purpose == null) ? null : "initiative-${local.domain}-${local.purpose}"
    policy_assignment = (local.policy == null || local.policy_scope == null) ? null : "assign-${local.policy}-${local.policy_scope}"

    # ---- Entra ID ----
    entra_security_group = (local.entra_dom == null || local.entra_role == null) ? null : "AZ-${local.entra_dom}-${local.entra_role}"

    # ---- Private DNS ----
    private_dns_zone = local.domain == null ? null : "${local.domain}-pdns"
  }
}
