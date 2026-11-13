# PHASE 2: Windows Server 2022 Datacenter Gen2, without changing legacy Linux addresses.
resource "azurerm_windows_virtual_machine" "vm" {
  for_each = local.windows_connectors

  name                       = each.value.name
  computer_name              = coalesce(each.value.computer_name, each.value.name)
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  size                       = each.value.vm_size
  zone                       = each.value.zone
  admin_username             = each.value.admin_username
  admin_password             = lookup(var.admin_passwords, each.key, null)
  network_interface_ids      = [module.network_interfaces[each.key].id]
  provision_vm_agent         = each.value.provision_vm_agent
  allow_extension_operations = each.value.allow_extension_operations
  encryption_at_host_enabled = each.value.encryption_at_host_enabled
  secure_boot_enabled        = each.value.secure_boot_enabled
  vtpm_enabled               = each.value.vtpm_enabled
  automatic_updates_enabled  = true
  patch_mode                 = "AutomaticByOS"
  patch_assessment_mode      = "AutomaticByPlatform"
  timezone                   = each.value.timezone
  license_type               = each.value.license_type
  source_image_id            = each.value.source_image_id
  tags                       = module.tags.tags

  os_disk {
    name                   = each.value.os_disk.name
    caching                = each.value.os_disk.caching
    storage_account_type   = each.value.os_disk.storage_account_type
    disk_size_gb           = each.value.os_disk.disk_size_gb
    disk_encryption_set_id = each.value.os_disk.disk_encryption_set_id
  }

  dynamic "source_image_reference" {
    for_each = each.value.source_image_id == null ? [coalesce(each.value.source_image_reference, {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-g2"
      version   = "latest"
    })] : []
    content {
      publisher = source_image_reference.value.publisher
      offer     = source_image_reference.value.offer
      sku       = source_image_reference.value.sku
      version   = source_image_reference.value.version
    }
  }

  dynamic "identity" {
    for_each = each.value.identity == null ? [] : [each.value.identity]
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  boot_diagnostics {
    storage_account_uri = try(each.value.boot_diagnostics.storage_account_uri, null)
  }

  lifecycle {
    precondition {
      condition     = length(coalesce(each.value.computer_name, each.value.name)) <= 15
      error_message = "Windows computer_name must be at most 15 characters; set it explicitly when the Azure VM name is longer."
    }
  }
  depends_on = [terraform_data.connector_contract]
}

resource "terraform_data" "windows_runtime_contract" {
  input = keys(var.windows_bootstrap)
  lifecycle {
    precondition {
      condition     = !var.require_windows_runtime || (length(var.connectors) > 0 && alltrue([for key, connector in var.connectors : connector.os_type == "Windows" && contains(keys(var.windows_bootstrap), key)]))
      error_message = "Production Windows rollout requires a bootstrap entry for every connector; no Linux or unbootstrapped hosts may be included."
    }
    precondition {
      condition = !var.require_windows_runtime || alltrue([for connector in values(local.windows_connectors) :
        connector.source_image_id != null || try(connector.source_image_reference.version != "latest" && can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", connector.source_image_reference.version)), false)
      ])
      error_message = "Production connectors require an explicit approved image version or version-specific image ID, not latest."
    }
    precondition {
      condition = !var.require_windows_runtime || alltrue([for key, config in var.windows_bootstrap : try(
        length(distinct([for peer_key, peer in var.windows_bootstrap : var.connectors[peer_key].zone
        if lower(peer.key_vault_id) == lower(config.key_vault_id) && lower(peer.token_secret_name) == lower(config.token_secret_name) && var.connectors[peer_key].zone != null])) >= 2, false)
      ])
      error_message = "Every production tunnel token must have connectors in at least two distinct availability zones."
    }
    precondition {
      condition = alltrue([for key, config in var.windows_bootstrap : try(
        var.connectors[key].os_type == "Windows" &&
        contains(["SystemAssigned", "SystemAssigned, UserAssigned"], var.connectors[key].identity.type) &&
      var.connectors[key].provision_vm_agent && var.connectors[key].allow_extension_operations, false)])
      error_message = "Windows bootstrap requires a Windows connector with system-assigned identity and VM agent/extension operations."
    }
    precondition {
      condition = alltrue([for config in values(var.windows_bootstrap) :
        tonumber(split(".", config.cloudflared_version)[0]) > 2025 ||
        (tonumber(split(".", config.cloudflared_version)[0]) == 2025 && tonumber(split(".", config.cloudflared_version)[1]) >= 4)
      ])
      error_message = "Token-file bootstrap requires cloudflared 2025.4.0 or newer."
    }
    precondition {
      condition = alltrue([for config in values(var.windows_bootstrap) :
        lower(trimsuffix(split("/", config.key_vault_uri)[2], ".vault.azure.net")) == lower(reverse(split("/", config.key_vault_id))[0])
      ])
      error_message = "Key Vault URI and resource ID must identify the same vault."
    }
  }
}

resource "azurerm_virtual_machine_extension" "domain_join" {
  for_each = { for key, connector in local.windows_connectors : key => connector.domain_join if connector.domain_join != null }

  name                       = "domain-join"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm[each.key].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true
  settings = jsonencode({
    Name    = each.value.domain
    User    = each.value.username
    OUPath  = each.value.ou_path
    Restart = "true"
    Options = "3"
  })
  protected_settings = jsonencode({ Password = lookup(var.domain_join_passwords, each.value.password_key, "") })
  tags               = module.tags.tags
  lifecycle {
    precondition {
      condition     = try(length(trimspace(var.domain_join_passwords[each.value.password_key])) > 0, false) && (strcontains(each.value.username, "@") || strcontains(each.value.username, "\\"))
      error_message = "Domain join requires the sensitive password entry and an approved domain-qualified join account."
    }
  }
}

resource "azurerm_role_assignment" "tunnel_token_reader" {
  for_each = { for key, config in var.windows_bootstrap : key => config if contains(keys(local.windows_connectors), key) }

  scope                            = "${each.value.key_vault_id}/secrets/${each.value.token_secret_name}"
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = azurerm_windows_virtual_machine.vm[each.key].identity[0].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
  depends_on                       = [terraform_data.windows_runtime_contract]
}

resource "azurerm_virtual_machine_run_command" "cloudflared" {
  for_each = { for key, config in var.windows_bootstrap : key => config if contains(keys(local.windows_connectors), key) }

  name               = "cloudflared-bootstrap"
  virtual_machine_id = azurerm_windows_virtual_machine.vm[each.key].id
  location           = module.resource_group.location
  # Managed Run Command avoids cmd.exe's command-length limit and does not
  # compete for the VM's single Custom Script Extension slot. No token in state.
  source {
    script = templatefile("${path.module}/scripts/bootstrap-windows.ps1.tftpl", {
      configuration = base64encode(jsonencode(each.value))
    })
  }
  lifecycle {
    postcondition {
      condition     = try(self.instance_view[0].exit_code == 0 && self.instance_view[0].execution_state == "Succeeded", false)
      error_message = "Windows bootstrap did not finish successfully. Review restricted VM logs and identity/network readiness before accepting the deployment."
    }
  }
  tags = merge(module.tags.tags, {
    cloudflare_tunnel_scope = sha256(lower("${each.value.key_vault_id}/secrets/${each.value.token_secret_name}"))
  })
  depends_on = [azurerm_role_assignment.tunnel_token_reader, azurerm_virtual_machine_extension.extension]
}

output "windows_runtime_command_ids" {
  value       = { for key, command in azurerm_virtual_machine_run_command.cloudflared : key => command.id }
  description = "Managed bootstrap commands; success includes local tunnel readiness, not external application acceptance."
}
