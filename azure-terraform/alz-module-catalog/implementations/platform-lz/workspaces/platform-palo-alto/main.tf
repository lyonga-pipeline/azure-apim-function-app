data "tfe_outputs" "connectivity" {
  count        = var.use_tfe_outputs && var.tfe_organization != null ? 1 : 0
  organization = var.tfe_organization
  workspace    = var.connectivity_workspace_name
}

locals {
  connectivity_outputs = merge(
    try(data.tfe_outputs.connectivity[0].nonsensitive_values, {}),
    try(data.tfe_outputs.connectivity[0].values, {})
  )

  resource_group_name = coalesce(try(var.palo_alto.resource_group_name, null), try(local.connectivity_outputs.hub_resource_group_name, null), try(local.connectivity_outputs.resource_group_name, null), "unused-disabled-rg")

  network_interfaces = {
    for nic_key, nic in try(var.palo_alto.network_interfaces, {}) : nic_key => merge({ name = module.naming_nic[nic_key].network_interface }, nic, {
      ip_configurations = {
        for ip_key, cfg in nic.ip_configurations : ip_key => merge(cfg, {
          subnet_id = coalesce(try(cfg.subnet_id, null), try(local.connectivity_outputs.subnet_ids[cfg.subnet_key], null))
        })
      }
    })
  }

  load_balancers = {
    for lb_key, lb in try(var.palo_alto.load_balancers, {}) : lb_key => merge({ name = module.naming_lb[lb_key].load_balancer }, lb, {
      frontend_ip_configurations = {
        for frontend_key, frontend in lb.frontend_ip_configurations : frontend_key => merge(frontend, {
          subnet_id = coalesce(try(frontend.subnet_id, null), try(local.connectivity_outputs.subnet_ids[frontend.subnet_key], null))
        })
      }
    })
  }

  # Inject the (sensitive) bootstrap storage key per firewall when the caller
  # points at an EXTERNAL bootstrap storage account (phase-1 output). Omit the
  # key entirely to use this pattern's own bootstrap storage.
  virtual_machines = {
    for vm_key, vm in try(var.palo_alto.virtual_machines, {}) : vm_key => merge(
      { name = module.naming_vm[vm_key].firewall_vm },
      try(var.palo_alto_bootstrap_storage_keys[vm_key], null) == null ? vm : merge(vm, {
        bootstrap = merge(try(vm.bootstrap, {}), { storage_account_key = var.palo_alto_bootstrap_storage_keys[vm_key] })
      })
    )
  }

  # Resolve subnet_key -> subnet_id for the bootstrap storage service endpoint
  # and the bootstrap Key Vault private endpoint. `network_rules.allowed_subnet_keys`
  # / `network.allowed_subnet_keys` in tfvars resolve against the connectivity output.
  _bsa    = try(var.palo_alto.bootstrap_storage_account, try(var.palo_alto.bootstrap, null))
  _bsa_nr = try(local._bsa.network_rules, null)
  bootstrap_storage_account = local._bsa == null ? null : {
    name                            = local._bsa.name
    account_replication_type        = try(local._bsa.account_replication_type, "ZRS")
    public_network_access_enabled   = try(local._bsa.public_network_access_enabled, false)
    shared_access_key_enabled       = try(local._bsa.shared_access_key_enabled, true)
    default_to_oauth_authentication = try(local._bsa.default_to_oauth_authentication, false)
    file_shares                     = try(local._bsa.file_shares, {})
    network_rules = local._bsa_nr == null ? null : {
      default_action = try(local._bsa_nr.default_action, "Deny")
      bypass         = try(local._bsa_nr.bypass, ["AzureServices"])
      ip_rules       = try(local._bsa_nr.ip_rules, [])
      virtual_network_subnet_ids = concat(
        try(local._bsa_nr.virtual_network_subnet_ids, []),
        [for k in try(local._bsa_nr.allowed_subnet_keys, []) : local.connectivity_outputs.subnet_ids[k]],
      )
    }
  }

  _bkv    = try(var.palo_alto.bootstrap_key_vault, null)
  _bkv_pe = try(local._bkv.private_endpoint, null)
  bootstrap_key_vault = local._bkv == null ? null : {
    name                       = local._bkv.name
    tenant_id                  = local._bkv.tenant_id
    sku_name                   = try(local._bkv.sku_name, "premium")
    purge_protection_enabled   = try(local._bkv.purge_protection_enabled, true)
    soft_delete_retention_days = try(local._bkv.soft_delete_retention_days, 90)
    network = {
      mode              = try(local._bkv.network.mode, "private")
      allowed_ip_ranges = try(local._bkv.network.allowed_ip_ranges, [])
      allowed_subnet_ids = concat(
        try(local._bkv.network.allowed_subnet_ids, []),
        [for k in try(local._bkv.network.allowed_subnet_keys, []) : local.connectivity_outputs.subnet_ids[k]],
      )
    }
    private_endpoint = local._bkv_pe == null ? null : {
      name                 = local._bkv_pe.name
      subnet_id            = coalesce(try(local._bkv_pe.subnet_id, null), try(local.connectivity_outputs.subnet_ids[local._bkv_pe.subnet_key], null))
      private_dns_zone_ids = try(local._bkv_pe.private_dns_zone_ids, [])
    }
  }
}

module "palo_alto" {
  source = "../../../../patterns/terraform-azurerm-compeer-palo-alto-hub"

  providers = {
    azurerm = azurerm
  }

  enabled                   = try(var.palo_alto.enabled, false)
  resource_group_name       = local.resource_group_name
  location                  = var.location
  tags                      = merge(var.tags, try(var.palo_alto.tags, {}))
  bootstrap_storage_account = local.bootstrap_storage_account
  bootstrap_key_vault       = local.bootstrap_key_vault
  bootstrap_share_layout    = try(var.palo_alto.bootstrap_share_layout, {})
  marketplace_agreement     = try(var.palo_alto.marketplace_agreement, { enabled = false })
  public_ips                = local.std_pip
  network_interfaces        = local.network_interfaces
  load_balancers            = local.load_balancers
  virtual_machines          = local.virtual_machines
}
