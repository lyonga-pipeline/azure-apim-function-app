# CAF-style deterministic naming. `names` gives `<abbr>-<org>-<workload>-<env>-<region>-<instance>`
# per resource type; `names_nodash` gives the compacted form for resources that
# disallow separators (storage accounts, key vaults, ...).

locals {
  region_short_builtin = {
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
    uksouth        = "uks"
    westeurope     = "weu"
    northeurope    = "neu"
  }
  region_short = merge(local.region_short_builtin, var.region_short_overrides)
  rs           = lookup(local.region_short, lower(var.region), lower(var.region))
  s            = var.separator

  # resource type -> abbreviation (Microsoft CAF recommended abbreviations)
  abbr = {
    resource_group           = "rg"
    virtual_network          = "vnet"
    subnet                   = "snet"
    network_security_group   = "nsg"
    route_table              = "rt"
    public_ip                = "pip"
    load_balancer            = "lb"
    nat_gateway              = "ng"
    private_endpoint         = "pep"
    network_interface        = "nic"
    firewall                 = "afw"
    bastion_host             = "bas"
    vpn_gateway              = "vpng"
    expressroute_gateway     = "ergw"
    local_network_gateway    = "lgw"
    virtual_wan              = "vwan"
    key_vault                = "kv"
    storage_account          = "st"
    log_analytics            = "log"
    app_insights             = "appi"
    automation_account       = "aa"
    recovery_services_vault  = "rsv"
    data_collection_endpoint = "dce"
    data_collection_rule     = "dcr"
    action_group             = "ag"
    app_service_plan         = "asp"
    app_service              = "app"
    function_app             = "func"
    api_management           = "apim"
    application_gateway      = "agw"
    container_registry       = "cr"
    aks_cluster              = "aks"
    sql_server               = "sql"
    sql_database             = "sqldb"
    cosmos_db                = "cosmos"
    redis                    = "redis"
    service_bus              = "sb"
    event_grid_topic         = "evgt"
    event_hub_namespace      = "evhns"
    user_assigned_identity   = "id"
    managed_hsm              = "hsm"
    private_dns_resolver     = "dnspr"
  }

  base        = join(local.s, compact([var.org, var.workload, var.environment, local.rs, var.instance]))
  base_nodash = lower(replace("${var.org}${var.workload}${var.environment}${local.rs}${var.instance}", "-", ""))

  names = { for k, a in local.abbr : k => "${a}${local.s}${local.base}" }
  # No-separator form, truncated to 24 (storage account max); dedupe with instance.
  names_nodash = { for k, a in local.abbr : k => substr(lower("${a}${local.base_nodash}"), 0, 24) }
}
