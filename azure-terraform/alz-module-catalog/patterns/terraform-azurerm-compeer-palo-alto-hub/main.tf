locals {
  enabled_public_ips = var.enabled ? var.public_ips : {}

  enabled_network_interfaces = var.enabled ? {
    for key, nic in var.network_interfaces : key => merge(nic, {
      ip_configurations = {
        for ip_key, ip_configuration in nic.ip_configurations : ip_key => merge(ip_configuration, {
          public_ip_address_id = try(ip_configuration.public_ip_key, null) == null ? null : module.public_ips[ip_configuration.public_ip_key].id
        })
      }
    })
  } : {}

  enabled_load_balancers = var.enabled ? {
    for key, lb in var.load_balancers : key => merge(lb, {
      frontend_ip_configurations = {
        for frontend_key, frontend in lb.frontend_ip_configurations : frontend_key => merge(frontend, {
          public_ip_address_id = try(frontend.public_ip_key, null) == null ? null : module.public_ips[frontend.public_ip_key].id
        })
      }
    })
  } : {}
}

resource "terraform_data" "vmseries_contract" {
  input = {
    local_vmseries_keys  = sort(keys(var.virtual_machines))
    vendor_vmseries_keys = sort(keys(var.vendor_vmseries))
  }

  lifecycle {
    precondition {
      condition     = !(length(var.virtual_machines) > 0 && length(var.vendor_vmseries) > 0)
      error_message = "Configure either virtual_machines or vendor_vmseries, not both, to avoid duplicate firewall ownership."
    }
  }
}

resource "azurerm_marketplace_agreement" "palo_alto" {
  count = var.enabled && coalesce(try(var.marketplace_agreement.enabled, null), false) ? 1 : 0

  publisher = try(var.marketplace_agreement.publisher, "paloaltonetworks")
  offer     = try(var.marketplace_agreement.offer, "vmseries-flex")
  plan      = try(var.marketplace_agreement.plan, "bundle2")
}

module "bootstrap_storage" {
  source = "../../modules/terraform-azurerm-compeer-storage-account"
  count  = var.enabled && var.bootstrap_storage_account != null ? 1 : 0

  name                              = var.bootstrap_storage_account.name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  account_replication_type          = try(var.bootstrap_storage_account.account_replication_type, "ZRS")
  public_network_access_enabled     = try(var.bootstrap_storage_account.public_network_access_enabled, false)
  shared_access_key_enabled         = try(var.bootstrap_storage_account.shared_access_key_enabled, true)
  default_to_oauth_authentication   = try(var.bootstrap_storage_account.default_to_oauth_authentication, false)
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true
  network_rules                     = try(var.bootstrap_storage_account.network_rules, null)
  tags                              = var.tags
}

resource "azurerm_storage_share" "bootstrap" {
  for_each = var.enabled && var.bootstrap_storage_account != null ? try(var.bootstrap_storage_account.file_shares, {}) : {}

  name                 = each.key
  storage_account_name = module.bootstrap_storage[0].name
  quota                = try(each.value.quota, 5)
}

module "public_ips" {
  source   = "../../modules/terraform-azurerm-compeer-public-ip"
  for_each = local.enabled_public_ips

  name                    = each.value.name
  resource_group_name     = var.resource_group_name
  location                = var.location
  allocation_method       = try(each.value.allocation_method, "Static")
  sku                     = try(each.value.sku, "Standard")
  sku_tier                = try(each.value.sku_tier, "Regional")
  domain_name_label       = try(each.value.domain_name_label, null)
  idle_timeout_in_minutes = try(each.value.idle_timeout_in_minutes, 4)
  zones                   = try(each.value.zones, ["1", "2", "3"])
  tags                    = var.tags
}

module "network_interfaces" {
  source   = "../../modules/terraform-azurerm-compeer-network-interface"
  for_each = local.enabled_network_interfaces

  name                           = each.value.name
  resource_group_name            = var.resource_group_name
  location                       = var.location
  dns_servers                    = try(each.value.dns_servers, null)
  accelerated_networking_enabled = try(each.value.accelerated_networking_enabled, true)
  ip_forwarding_enabled          = try(each.value.ip_forwarding_enabled, true)
  ip_configurations              = each.value.ip_configurations
  tags                           = var.tags
}

module "load_balancers" {
  source   = "../../modules/terraform-azurerm-compeer-load-balancer"
  for_each = local.enabled_load_balancers

  name                       = each.value.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  sku                        = try(each.value.sku, "Standard")
  frontend_ip_configurations = each.value.frontend_ip_configurations
  backend_address_pools      = try(each.value.backend_address_pools, {})
  probes                     = try(each.value.probes, {})
  rules                      = try(each.value.rules, {})
  tags                       = var.tags
}

resource "azurerm_linux_virtual_machine" "this" {
  for_each = var.enabled ? var.virtual_machines : {}

  name                            = each.value.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = each.value.size
  zone                            = try(each.value.zone, null)
  admin_username                  = each.value.admin_username
  admin_password                  = try(each.value.admin_password, null)
  disable_password_authentication = try(each.value.disable_password_authentication, true)
  network_interface_ids           = [for nic_key in each.value.network_interface_keys : module.network_interfaces[nic_key].id]
  tags                            = var.tags

  os_disk {
    name                 = try(each.value.os_disk.name, null)
    caching              = try(each.value.os_disk.caching, "ReadWrite")
    storage_account_type = try(each.value.os_disk.storage_account_type, "Premium_LRS")
    disk_size_gb         = try(each.value.os_disk.disk_size_gb, null)
  }

  dynamic "source_image_reference" {
    for_each = [each.value.source_image_reference]
    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = try(source_image_reference.value.version, "latest")
    }
  }

  dynamic "plan" {
    for_each = try(each.value.plan, null) == null ? [] : [each.value.plan]
    content {
      name      = plan.value.name
      publisher = plan.value.publisher
      product   = plan.value.product
    }
  }

  dynamic "admin_ssh_key" {
    for_each = try(each.value.admin_ssh_keys, [])
    content {
      username   = admin_ssh_key.value.username
      public_key = admin_ssh_key.value.public_key
    }
  }

  dynamic "boot_diagnostics" {
    for_each = try(each.value.boot_diagnostics_storage_account_uri, null) == null ? [] : [each.value.boot_diagnostics_storage_account_uri]
    content {
      storage_account_uri = boot_diagnostics.value
    }
  }

  lifecycle {
    precondition {
      condition     = try(each.value.disable_password_authentication, true) || try(each.value.admin_password, null) != null
      error_message = "admin_password is required when disable_password_authentication is false."
    }
  }

  depends_on = [terraform_data.vmseries_contract, azurerm_marketplace_agreement.palo_alto]
}

module "vendor_vmseries" {
  source   = "PaloAltoNetworks/swfw-modules/azurerm//modules/vmseries"
  version  = "3.5.1"
  for_each = var.enabled ? var.vendor_vmseries : {}

  name                = each.value.name
  resource_group_name = var.resource_group_name
  region              = var.location
  tags                = var.tags

  authentication = merge(
    {
      username                        = try(each.value.username, "panadmin")
      password                        = try(var.vendor_vmseries_passwords[each.key], null)
      disable_password_authentication = try(each.value.disable_password_authentication, true)
      ssh_keys                        = try(each.value.ssh_keys, [])
    },
    try(each.value.authentication, {})
  )

  image = merge(
    {
      publisher               = try(each.value.img_publisher, "paloaltonetworks")
      offer                   = try(each.value.img_offer, "vmseries-flex")
      sku                     = try(each.value.img_sku, "byol")
      version                 = try(each.value.img_version, "latest")
      enable_marketplace_plan = try(each.value.enable_plan, true)
      custom_id               = try(each.value.custom_image_id, null)
    },
    try(each.value.image, {})
  )

  virtual_machine = merge(
    {
      size                         = try(each.value.vm_size, "Standard_D3_v2")
      zone                         = try(each.value.avzone, null)
      disk_type                    = try(each.value.managed_disk_type, "StandardSSD_LRS")
      disk_name                    = try(each.value.os_disk_name, "${each.value.name}-osdisk")
      avset_id                     = try(each.value.avset_id, null)
      accelerated_networking       = try(each.value.accelerated_networking, true)
      bootstrap_options            = try(each.value.bootstrap_options, null)
      boot_diagnostics_storage_uri = try(each.value.diagnostics_storage_uri, null)
      identity_type                = try(each.value.identity_type, "SystemAssigned")
      identity_ids                 = try(each.value.identity_ids, [])
    },
    try(each.value.virtual_machine, {})
  )

  interfaces = each.value.interfaces

  depends_on = [terraform_data.vmseries_contract, azurerm_marketplace_agreement.palo_alto]
}
