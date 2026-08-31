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
    for nic_key, nic in try(var.palo_alto.network_interfaces, {}) : nic_key => merge(nic, {
      ip_configurations = {
        for ip_key, cfg in nic.ip_configurations : ip_key => merge(cfg, {
          subnet_id = coalesce(try(cfg.subnet_id, null), try(local.connectivity_outputs.subnet_ids[cfg.subnet_key], null))
        })
      }
    })
  }

  load_balancers = {
    for lb_key, lb in try(var.palo_alto.load_balancers, {}) : lb_key => merge(lb, {
      frontend_ip_configurations = {
        for frontend_key, frontend in lb.frontend_ip_configurations : frontend_key => merge(frontend, {
          subnet_id = coalesce(try(frontend.subnet_id, null), try(local.connectivity_outputs.subnet_ids[frontend.subnet_key], null))
        })
      }
    })
  }

  vendor_vmseries = {
    for vm_key, vm in try(var.palo_alto.vendor_vmseries, {}) : vm_key => merge(vm, {
      interfaces = [
        for interface in try(vm.interfaces, []) : merge(interface, {
          subnet_id = coalesce(try(interface.subnet_id, null), try(local.connectivity_outputs.subnet_ids[interface.subnet_key], null))
        })
      ]
    })
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
  bootstrap_storage_account = try(var.palo_alto.bootstrap_storage_account, try(var.palo_alto.bootstrap, null))
  bootstrap_share_layout    = try(var.palo_alto.bootstrap_share_layout, {})
  marketplace_agreement     = try(var.palo_alto.marketplace_agreement, { enabled = false })
  public_ips                = try(var.palo_alto.public_ips, {})
  network_interfaces        = local.network_interfaces
  load_balancers            = local.load_balancers
  virtual_machines          = try(var.palo_alto.virtual_machines, {})
  vendor_vmseries           = local.vendor_vmseries
  vendor_vmseries_passwords = var.palo_alto_vendor_vmseries_passwords
}
