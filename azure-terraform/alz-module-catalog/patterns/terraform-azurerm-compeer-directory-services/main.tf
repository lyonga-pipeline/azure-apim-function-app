# =============================================================================
# ⚠ DEVIATION — TEMPORARY, PENDING AD-TEAM CONFIRMATION
#
# deploy-runbook.tf §7.2 / §15 state that AD DS role install and domain
# promotion are NOT Terraform-owned (preferred tooling: Ansible / PowerShell
# DSC), and that domain-admin secrets never flow through Terraform variables.
#
# This pattern currently DOES drive both, via:
#   - azurerm_virtual_machine_extension.ad_ds_role_install  (PowerShell)
#   - azurerm_virtual_machine_extension.ad_ds_promotion      (PowerShell)
#   - var.ad_ds_promotion_passwords  -> lands in Terraform state
#
# This is a TEMPORARY bridge so the DCs can stand up end-to-end. Before
# production authorization, the AD team must confirm one of:
#   (a) accept this as an approved deviation (record the exception), OR
#   (b) set every `ad_ds_role_install.enabled` / `ad_ds_promotion.enabled` to
#       false and hand promotion to the approved Ansible / DSC pipeline. The
#       VM / NIC / disk / diagnostics / lock resources below stay Terraform-owned
#       either way.
#
# TODO(ad-team): confirm (a) or (b); if (b), also remove
#                var.ad_ds_promotion_passwords and the related validations.
# =============================================================================

module "tags" {
  source = "../../modules/terraform-azurerm-compeer-platform-tags"

  environment           = var.environment
  application           = var.platform_tags.application
  owner                 = var.platform_tags.owner
  source_repo           = var.platform_tags.source_repo
  created_on            = var.platform_tags.created_on
  criticality_tier      = var.platform_tags.criticality_tier
  data_classification   = var.platform_tags.data_classification
  lifecycle_state       = var.platform_tags.lifecycle_state
  cost_center           = var.platform_tags.cost_center
  gl_category           = var.platform_tags.gl_category
  application_component = var.platform_tags.application_component
  modified_on           = var.platform_tags.modified_on
  created_by            = var.platform_tags.created_by
  dr_tier               = var.platform_tags.dr_tier
  expiration_date       = var.platform_tags.expiration_date
  additional_tags       = var.platform_tags.additional_tags
}

module "resource_group" {
  source = "../../modules/terraform-azurerm-compeer-resource-group"

  name     = var.resource_group.name
  location = var.location
  tags     = module.tags.tags
}

locals {
  default_windows_image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  data_disks = merge([
    for controller_key, controller in var.domain_controllers : {
      for disk_key, disk in try(controller.data_disks, {}) : "${controller_key}:${disk_key}" => merge(disk, {
        controller_key = controller_key
        disk_key       = disk_key
        zone           = coalesce(try(disk.zone, null), try(controller.zone, null))
      })
    }
  ]...)

  domain_joins = {
    for controller_key, controller in var.domain_controllers : controller_key => controller.domain_join
    if coalesce(try(controller.domain_join.enabled, null), false)
  }

  ad_ds_role_installs = {
    for controller_key, controller in var.domain_controllers : controller_key => controller.ad_ds_role_install
    if coalesce(try(controller.ad_ds_role_install.enabled, null), false)
  }

  ad_ds_promotions = {
    for controller_key, controller in var.domain_controllers : controller_key => controller.ad_ds_promotion
    if coalesce(try(controller.ad_ds_promotion.enabled, null), false)
  }

  ad_ds_promotion_domain_admin_password_keys = {
    for controller_key, promotion in local.ad_ds_promotions :
    controller_key => coalesce(try(promotion.domain_admin_password_key, null), controller_key)
  }

  ad_ds_promotion_safe_mode_password_keys = {
    for controller_key, promotion in local.ad_ds_promotions :
    controller_key => coalesce(
      try(promotion.safe_mode_admin_password_key, null),
      try(promotion.domain_admin_password_key, null),
      controller_key
    )
  }

  powershell_bool = {
    "false" = "$false"
    "true"  = "$true"
  }

  scope_ids = merge(
    {
      resource_group = module.resource_group.id
    },
    {
      for key, value in module.network_interfaces : "nic:${key}" => value.id
    },
    {
      for key, value in module.domain_controllers : "vm:${key}" => value.id
    },
    {
      for key, value in azurerm_managed_disk.data : "disk:${key}" => value.id
    },
    var.additional_scopes
  )

  role_assignment_inputs = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      scope = coalesce(
        try(assignment.scope, null),
        try(local.scope_ids[assignment.scope_key], null)
      )
    })
  }
}

resource "terraform_data" "controller_contract" {
  input = {
    domain_controller_keys  = sort(keys(var.domain_controllers))
    domain_join_keys        = sort(keys(local.domain_joins))
    ad_ds_role_install_keys = sort(keys(local.ad_ds_role_installs))
    ad_ds_promotion_keys    = sort(keys(local.ad_ds_promotions))
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for key in keys(var.domain_controllers) : contains(keys(var.admin_passwords), key)
      ])
      error_message = "admin_passwords must contain a sensitive password entry for each domain controller key."
    }

    precondition {
      condition = alltrue([
        for key, join in local.domain_joins : contains(keys(var.domain_join_passwords), coalesce(try(join.domain_password_key, null), key))
      ])
      error_message = "domain_join_passwords must contain a sensitive password entry for each enabled domain join."
    }

    precondition {
      condition = alltrue([
        for key, install in local.ad_ds_role_installs : length(try(install.features, [])) > 0
      ])
      error_message = "Each enabled AD DS role installation must include at least one Windows feature."
    }

    precondition {
      condition = alltrue([
        for key, promotion in local.ad_ds_promotions :
        length(trimspace(coalesce(try(promotion.domain_name, null), ""))) > 0 &&
        length(trimspace(coalesce(try(promotion.domain_admin_username, null), ""))) > 0
      ])
      error_message = "Each enabled AD DS promotion must set domain_name and domain_admin_username."
    }

    precondition {
      condition = alltrue([
        for key, promotion in local.ad_ds_promotions :
        contains(keys(var.ad_ds_promotion_passwords), local.ad_ds_promotion_domain_admin_password_keys[key])
      ])
      error_message = "ad_ds_promotion_passwords must contain a domain admin password for each enabled AD DS promotion."
    }

    precondition {
      condition = alltrue([
        for key, promotion in local.ad_ds_promotions :
        contains(keys(var.ad_ds_promotion_passwords), local.ad_ds_promotion_safe_mode_password_keys[key])
      ])
      error_message = "ad_ds_promotion_passwords must contain a safe mode administrator password for each enabled AD DS promotion."
    }
  }
}

module "network_interfaces" {
  source   = "../../modules/terraform-azurerm-compeer-network-interface"
  for_each = var.domain_controllers

  name                           = each.value.nic_name
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  dns_servers                    = try(each.value.dns_servers, null)
  accelerated_networking_enabled = try(each.value.accelerated_networking_enabled, true)
  ip_forwarding_enabled          = try(each.value.ip_forwarding_enabled, false)
  ip_configurations = {
    (try(each.value.ip_configuration_name, "primary")) = {
      subnet_id                     = each.value.subnet_id
      private_ip_address_allocation = try(each.value.private_ip_address_allocation, "Static")
      private_ip_address            = each.value.private_ip_address
      primary                       = true
    }
  }
  tags = module.tags.tags
}

module "domain_controllers" {
  source   = "../../modules/terraform-azurerm-compeer-windows-vm"
  for_each = var.domain_controllers

  name                       = each.value.name
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  vm_size                    = try(each.value.vm_size, "Standard_D2s_v5")
  network_interface_ids      = [module.network_interfaces[each.key].id]
  admin_username             = try(each.value.admin_username, "azureadmin")
  admin_password             = var.admin_passwords[each.key]
  computer_name              = try(each.value.computer_name, null)
  availability_set_id        = try(each.value.availability_set_id, null)
  zone                       = try(each.value.zone, null)
  source_image_id            = try(each.value.source_image_id, null)
  source_image_reference     = try(each.value.source_image_id, null) == null ? coalesce(try(each.value.source_image_reference, null), local.default_windows_image) : null
  plan                       = try(each.value.plan, null)
  license_type               = try(each.value.license_type, "Windows_Server")
  timezone                   = try(each.value.timezone, "UTC")
  provision_vm_agent         = try(each.value.provision_vm_agent, true)
  allow_extension_operations = try(each.value.allow_extension_operations, true)
  automatic_updates_enabled  = try(each.value.automatic_updates_enabled, try(each.value.enable_automatic_updates, true))
  patch_mode                 = try(each.value.patch_mode, "AutomaticByPlatform")
  patch_assessment_mode      = try(each.value.patch_assessment_mode, "AutomaticByPlatform")
  hotpatching_enabled        = try(each.value.hotpatching_enabled, false)
  secure_boot_enabled        = try(each.value.secure_boot_enabled, true)
  vtpm_enabled               = try(each.value.vtpm_enabled, true)
  encryption_at_host_enabled = try(each.value.encryption_at_host_enabled, true)
  identity                   = try(each.value.identity, null)
  boot_diagnostics           = try(each.value.boot_diagnostics, null)
  additional_capabilities    = try(each.value.additional_capabilities, null)
  os_disk = coalesce(try(each.value.os_disk, null), {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  })
  tags = module.tags.tags

  depends_on = [terraform_data.controller_contract]
}

resource "azurerm_managed_disk" "data" {
  for_each = local.data_disks

  name                 = each.value.name
  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  storage_account_type = try(each.value.storage_account_type, "Premium_LRS")
  create_option        = try(each.value.create_option, "Empty")
  disk_size_gb         = each.value.disk_size_gb
  zone                 = try(each.value.zone, null)
  tags                 = module.tags.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = local.data_disks

  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = module.domain_controllers[each.value.controller_key].id
  lun                = each.value.lun
  caching            = try(each.value.caching, "ReadOnly")
}

# Confirm with the AD team whether Terraform should own AD DS/DNS role
# installation before enabling this extension in an enterprise workspace.
resource "azurerm_virtual_machine_extension" "ad_ds_role_install" {
  for_each = local.ad_ds_role_installs

  name                 = try(each.value.name, "install-ad-dns")
  virtual_machine_id   = module.domain_controllers[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = try(each.value.type_handler_version, "1.10")

  settings = jsonencode({
    scriptVersion    = try(each.value.script_version, "v1")
    commandToExecute = "powershell -ExecutionPolicy Bypass -Command \"Install-WindowsFeature -Name ${join(",", try(each.value.features, ["AD-Domain-Services", "DNS"]))}${try(each.value.include_management_tools, true) ? " -IncludeManagementTools" : ""} -ErrorAction Stop\""
  })

  timeouts {
    create = try(each.value.timeouts.create, "60m")
    update = try(each.value.timeouts.update, "60m")
    read   = try(each.value.timeouts.read, "5m")
    delete = try(each.value.timeouts.delete, "60m")
  }

  depends_on = [terraform_data.controller_contract]
}

module "vm_diagnostics" {
  source = "../../modules/terraform-azurerm-compeer-diagnostic-settings"
  for_each = {
    for key, controller in var.domain_controllers : key => controller.diagnostics
    if coalesce(try(controller.diagnostics.enabled, null), false)
  }

  name                           = coalesce(try(each.value.name, null), "${module.domain_controllers[each.key].name}-diag")
  target_resource_id             = module.domain_controllers[each.key].id
  log_analytics_workspace_id     = try(each.value.log_analytics_workspace_id, null)
  log_analytics_destination_type = try(each.value.log_analytics_destination_type, null)
  storage_account_id             = try(each.value.storage_account_id, null)
  eventhub_authorization_rule_id = try(each.value.eventhub_authorization_rule_id, null)
  eventhub_name                  = try(each.value.eventhub_name, null)
  partner_solution_id            = try(each.value.partner_solution_id, null)
  logs                           = try(each.value.logs, {})
  metrics                        = try(each.value.metrics, {})
}

module "domain_join" {
  source   = "../../modules/terraform-azurerm-compeer-windows-vm-domain-join"
  for_each = local.domain_joins

  name                 = try(each.value.name, "domain-join")
  virtual_machine_id   = module.domain_controllers[each.key].id
  domain_name          = each.value.domain_name
  ou_path              = try(each.value.ou_path, null)
  domain_username      = each.value.domain_username
  domain_password      = var.domain_join_passwords[coalesce(try(each.value.domain_password_key, null), each.key)]
  restart              = try(each.value.restart, true)
  join_options         = try(each.value.join_options, 3)
  type_handler_version = try(each.value.type_handler_version, "1.3")

  depends_on = [
    terraform_data.controller_contract,
    azurerm_virtual_machine_extension.ad_ds_role_install
  ]
}

# Confirm with the AD team whether Terraform should own domain controller
# promotion. This is opt-in because promotion writes guest/AD state and places
# sensitive promotion material in the Terraform execution path.
resource "azurerm_virtual_machine_extension" "ad_ds_promotion" {
  for_each = local.ad_ds_promotions

  name                 = try(each.value.name, "promote-to-dc")
  virtual_machine_id   = module.domain_controllers[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = try(each.value.type_handler_version, "1.10")

  settings = jsonencode({
    scriptVersion = try(each.value.script_version, "v1")
  })

  protected_settings = jsonencode({
    commandToExecute = join(" ", compact([
      "powershell -ExecutionPolicy Bypass -Command \"",
      "$ErrorActionPreference = 'Stop';",
      "Install-WindowsFeature -Name ${join(",", try(each.value.features, ["AD-Domain-Services", "DNS"]))}${try(each.value.include_management_tools, true) ? " -IncludeManagementTools" : ""} -ErrorAction Stop;",
      "Import-Module ADDSDeployment;",
      "if ((Get-CimInstance Win32_ComputerSystem).DomainRole -ge 4) { Write-Output 'This VM is already a domain controller; skipping promotion.'; exit 0 };",
      "$domainPasswordPlain = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(lookup(var.ad_ds_promotion_passwords, local.ad_ds_promotion_domain_admin_password_keys[each.key], ""))}'));",
      "$safeModePasswordPlain = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(lookup(var.ad_ds_promotion_passwords, local.ad_ds_promotion_safe_mode_password_keys[each.key], ""))}'));",
      "$domainPassword = ConvertTo-SecureString $domainPasswordPlain -AsPlainText -Force;",
      "$safeModePassword = ConvertTo-SecureString $safeModePasswordPlain -AsPlainText -Force;",
      "$cred = New-Object System.Management.Automation.PSCredential('${coalesce(try(each.value.domain_admin_username, null), "")}', $domainPassword);",
      "Install-ADDSDomainController -DomainName '${coalesce(try(each.value.domain_name, null), "")}' -Credential $cred -SafeModeAdministratorPassword $safeModePassword -InstallDns:${local.powershell_bool[tostring(try(each.value.install_dns, true))]} -NoGlobalCatalog:${local.powershell_bool[tostring(try(each.value.no_global_catalog, false))]}${try(each.value.site_name, null) == null ? "" : " -SiteName '${each.value.site_name}'"} -CriticalReplicationOnly:${local.powershell_bool[tostring(try(each.value.critical_replication_only, false))]} -NoRebootOnCompletion:${local.powershell_bool[tostring(try(each.value.no_reboot_on_completion, true))]} -Force:${local.powershell_bool[tostring(try(each.value.force, true))]} -Confirm:$false;",
      "Write-Output 'Promotion command completed. Reboot may be required to finalize domain controller configuration.'\""
    ]))
  })

  timeouts {
    create = try(each.value.timeouts.create, "120m")
    update = try(each.value.timeouts.update, "120m")
    read   = try(each.value.timeouts.read, "5m")
    delete = try(each.value.timeouts.delete, "120m")
  }

  depends_on = [
    terraform_data.controller_contract,
    azurerm_virtual_machine_extension.ad_ds_role_install,
    module.domain_join
  ]
}

module "role_assignments" {
  source = "../../modules/terraform-azurerm-compeer-role-assignments"

  assignments = local.role_assignment_inputs
}

resource "azurerm_management_lock" "this" {
  for_each = var.management_locks

  name       = each.value.name
  scope      = coalesce(try(each.value.scope, null), try(local.scope_ids[each.value.scope_key], null))
  lock_level = each.value.lock_level
  notes      = try(each.value.notes, null)
}

module "operational_contracts" {
  source = "../../modules/terraform-azurerm-compeer-operational-contracts"

  contracts = var.operational_contracts
}

# Tier-0 backup enrolment (deploy-runbook.tf §12: DCs "must be covered by an
# AD-aware recovery procedure"). Backup POLICIES live in the platform-management
# recovery-services vault; this pattern enrols the DC VMs against one.
resource "azurerm_backup_protected_vm" "dc" {
  for_each = var.dc_backup == null ? {} : var.dc_backup.protected_controllers

  resource_group_name = var.dc_backup.vault_resource_group_name
  recovery_vault_name = var.dc_backup.vault_name
  source_vm_id        = module.domain_controllers[each.key].id
  backup_policy_id    = coalesce(try(each.value.backup_policy_id, null), var.dc_backup.default_backup_policy_id)
}
