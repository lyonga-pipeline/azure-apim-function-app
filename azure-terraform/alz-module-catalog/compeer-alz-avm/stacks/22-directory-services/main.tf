locals {
  tags = merge({
    ManagedBy = "Terraform"
    IaCSource = "CompeerHCP"
    Phase     = "1"
    Workload  = "directory-services"
  }, var.tags)

  data_disks = merge({}, [
    for controller_key, controller in var.domain_controllers : {
      for disk_key, disk in try(controller.data_disks, {}) : "${controller_key}-${disk_key}" => merge(disk, {
        controller_key = controller_key
        disk_key       = disk_key
      })
    }
  ]...)

  domain_join_controllers = {
    for key, controller in var.domain_controllers : key => controller
    if try(controller.domain_join, null) != null
  }

  default_windows_image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  default_operational_contracts = {
    domain_controller_promotion = {
      phase                = "Phase 1"
      implementation_state = "terraform-plus-manual"
      required_controls    = ["promote two zone-separated VMs into the existing forest", "place NTDS/SYSVOL on data disks", "validate replication health"]
      notes                = "IAM-07 Terraform deploys VMs, NICs, disks, and optional domain join. AD DS promotion is AD-owned state and should be completed by the AD runbook or approved configuration tooling."
    }
    ad_dns_forwarders = {
      phase                = "Phase 1"
      implementation_state = "manual-control"
      required_controls    = ["Azure private DNS zone forwarding", "on-premises conditional forwarders", "hub VNet DNS server settings"]
      notes                = "NET-27/NET-28 are DNS configuration controls owned by AD/network operations."
    }
  }
}

module "network_interface" {
  for_each = var.domain_controllers
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-network-interface/azurerm"
  version  = "1.0.0"

  name                           = each.value.network_interface_name
  resource_group_name            = var.resource_group_name
  location                       = var.location
  dns_servers                    = try(each.value.dns_servers, null)
  accelerated_networking_enabled = try(each.value.accelerated_networking_enabled, true)
  ip_forwarding_enabled          = false
  ip_configurations = {
    primary = {
      subnet_id                     = each.value.subnet_id
      private_ip_address_allocation = try(each.value.private_ip_address_allocation, "Static")
      private_ip_address            = try(each.value.private_ip_address, null)
      primary                       = true
    }
  }
  tags = local.tags
}

module "domain_controller" {
  for_each = var.domain_controllers
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-windows-vm/azurerm"
  version  = "1.0.0"

  name                       = each.value.name
  computer_name              = try(each.value.computer_name, null)
  resource_group_name        = var.resource_group_name
  location                   = var.location
  vm_size                    = each.value.vm_size
  network_interface_ids      = [module.network_interface[each.key].id]
  admin_username             = each.value.admin_username
  admin_password             = var.admin_passwords[each.key]
  zone                       = try(each.value.zone, null)
  availability_set_id        = try(each.value.availability_set_id, null)
  source_image_id            = try(each.value.source_image_id, null)
  source_image_reference     = try(each.value.source_image_id, null) == null ? coalesce(try(each.value.source_image_reference, null), local.default_windows_image) : null
  license_type               = try(each.value.license_type, "Windows_Server")
  timezone                   = try(each.value.timezone, "UTC")
  patch_mode                 = try(each.value.patch_mode, "AutomaticByPlatform")
  patch_assessment_mode      = try(each.value.patch_assessment_mode, "AutomaticByPlatform")
  secure_boot_enabled        = try(each.value.secure_boot_enabled, true)
  vtpm_enabled               = try(each.value.vtpm_enabled, true)
  encryption_at_host_enabled = try(each.value.encryption_at_host_enabled, true)
  boot_diagnostics           = try(each.value.boot_diagnostics, null)
  os_disk                    = try(each.value.os_disk, null)
  tags                       = local.tags
}

resource "azurerm_managed_disk" "data" {
  for_each = local.data_disks

  name                 = each.value.name
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = try(each.value.storage_account_type, "Premium_LRS")
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb
  zone                 = try(var.domain_controllers[each.value.controller_key].zone, null)
  tags                 = local.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = local.data_disks

  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = module.domain_controller[each.value.controller_key].id
  lun                = each.value.lun
  caching            = try(each.value.caching, "ReadOnly")
}

module "domain_join" {
  for_each = local.domain_join_controllers
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-windows-vm-domain-join/azurerm"
  version  = "1.0.0"

  name               = try(each.value.domain_join.name, "domain-join")
  virtual_machine_id = module.domain_controller[each.key].id
  domain_name        = each.value.domain_join.domain_name
  ou_path            = try(each.value.domain_join.ou_path, null)
  domain_username    = each.value.domain_join.domain_username
  domain_password    = var.domain_join_passwords[each.key]
  restart            = try(each.value.domain_join.restart, true)
  join_options       = try(each.value.domain_join.join_options, 3)
}

module "vm_diagnostics" {
  for_each = var.log_analytics_workspace_id == null ? {} : var.domain_controllers
  source   = "app.terraform.io/Compeer-Financial-Services/compeer-diagnostic-settings/azurerm"
  version  = "1.0.0"

  name                       = "${each.value.name}-law"
  target_resource_id         = module.domain_controller[each.key].id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  metrics = {
    all = { category = "AllMetrics" }
  }
}

module "operational_contracts" {
  source  = "app.terraform.io/Compeer-Financial-Services/compeer-operational-contracts/azurerm"
  version = "1.0.0"

  contracts = merge(local.default_operational_contracts, var.operational_contracts)
}
