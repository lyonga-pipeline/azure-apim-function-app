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

  # Bootstrap storage details for azure-file-share mode. The account name/key
  # can come from the caller (phase-1 output) or, when this pattern owns the
  # bootstrap storage, from the data lookup below.
  managed_bootstrap_name = var.enabled && var.bootstrap_storage_account != null ? var.bootstrap_storage_account.name : null

  managed_bootstrap_key = try(data.azurerm_storage_account.bootstrap[0].primary_access_key, "")

  # PAN-OS bootstrap custom_data, computed per firewall VM.
  vm_custom_data = {
    for key, vm in var.virtual_machines : key => (
      try(vm.bootstrap.mode, "none") == "azure-file-share" ? base64encode(join("\n", [
        "storage-account=${coalesce(try(vm.bootstrap.storage_account_name, ""), local.managed_bootstrap_name, " ")}",
        "access-key=${coalesce(try(vm.bootstrap.storage_account_key, ""), local.managed_bootstrap_key, " ")}",
        "file-share=${try(vm.bootstrap.file_share_name, "bootstrap")}",
        "share-directory=${try(vm.bootstrap.share_directory, "None")}",
      ])) :
      try(vm.bootstrap.mode, "none") == "custom-data" ? base64encode(coalesce(try(vm.bootstrap.custom_data, null), try(vm.bootstrap.init_cfg_content, null))) :
      null
    )
  }

  # True when any firewall uses azure-file-share against this pattern's own
  # bootstrap storage (no caller-supplied key).
  need_managed_bootstrap_key = local.managed_bootstrap_name != null && anytrue([
    for vm in values(var.virtual_machines) :
    try(vm.bootstrap.mode, "none") == "azure-file-share" && try(vm.bootstrap.storage_account_key, null) == null
  ])

  bootstrap_share_directories = var.enabled && var.bootstrap_storage_account != null ? {
    for item in flatten([
      for share_name, layout in var.bootstrap_share_layout : [
        for dir in layout.directories : { key = "${share_name}/${dir}", share = share_name, name = dir }
      ]
    ]) : item.key => item
  } : {}

  bootstrap_share_files = var.enabled && var.bootstrap_storage_account != null ? {
    for item in flatten([
      for share_name, layout in var.bootstrap_share_layout : [
        for file_key, file in layout.files : {
          key         = "${share_name}/${file_key}"
          share       = share_name
          name        = file_key
          path        = try(file.path, null)
          source_path = try(file.source_path, null)
          content     = try(file.content, null)
        }
      ]
    ]) : item.key => item
  } : {}
}

resource "terraform_data" "bootstrap_contract" {
  count = var.enabled ? 1 : 0

  input = { firewalls = sort(keys(var.virtual_machines)) }

  lifecycle {
    precondition {
      condition = !anytrue([
        for vm in values(var.virtual_machines) :
        try(vm.bootstrap.mode, "none") == "azure-file-share" &&
        try(vm.bootstrap.storage_account_name, null) == null &&
        var.bootstrap_storage_account == null
      ])
      error_message = "A firewall uses bootstrap.mode = azure-file-share without an external storage_account_name/key, so var.bootstrap_storage_account must be set."
    }
  }
}

data "azurerm_storage_account" "bootstrap" {
  count = local.need_managed_bootstrap_key ? 1 : 0

  name                = var.bootstrap_storage_account.name
  resource_group_name = var.resource_group_name

  depends_on = [module.bootstrap_storage]
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

  name               = each.key
  storage_account_id = module.bootstrap_storage[0].id
  quota              = try(each.value.quota, 5)
}

resource "azurerm_storage_share_directory" "bootstrap" {
  for_each = local.bootstrap_share_directories

  name             = each.value.name
  storage_share_id = azurerm_storage_share.bootstrap[each.value.share].id
}

# Inline file content is materialized to a local file first, then uploaded.
resource "local_file" "bootstrap" {
  for_each = { for k, v in local.bootstrap_share_files : k => v if v.content != null }

  filename = "${path.module}/.bootstrap-render/${replace(each.key, "/", "_")}"
  content  = each.value.content
}

resource "azurerm_storage_share_file" "bootstrap" {
  for_each = local.bootstrap_share_files

  name             = each.value.name
  storage_share_id = azurerm_storage_share.bootstrap[each.value.share].id
  path             = each.value.path
  source           = each.value.content != null ? local_file.bootstrap[each.key].filename : each.value.source_path

  depends_on = [azurerm_storage_share_directory.bootstrap]
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
  custom_data                     = local.vm_custom_data[each.key]
  tags                            = var.tags

  dynamic "identity" {
    for_each = try(each.value.identity, null) == null ? [] : [each.value.identity]
    content {
      type         = try(identity.value.type, "SystemAssigned")
      identity_ids = try(identity.value.identity_ids, [])
    }
  }

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

  depends_on = [
    azurerm_marketplace_agreement.palo_alto,
    azurerm_storage_share_file.bootstrap,
  ]
}
