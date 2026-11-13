mock_provider "azurerm" {}

variables {
  subscription_id = "11111111-1111-1111-1111-111111111111"
  location        = "centralus"
  environment     = "prod"
  resource_group  = { name = "platform-cus-prod-cfc-rg" }
  connectors = {
    np01 = {
      os_type   = "Windows"
      name      = "cus-np-cft-01"
      nic_name  = "cus-np-cft-01-nic"
      vm_size   = "Standard_D4s_v5"
      zone      = "1"
      subnet_id = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub/subnets/connectors"
      identity  = { type = "SystemAssigned" }
      os_disk   = { storage_account_type = "StandardSSD_LRS" }
    }
  }
  admin_passwords = { np01 = "NotAReal!Password2026" }
}

run "windows_2022_image_and_security_defaults" {
  command = plan
  assert {
    condition = (length(azurerm_linux_virtual_machine.vm) == 0 &&
      azurerm_windows_virtual_machine.vm["np01"].source_image_reference[0].sku == "2022-datacenter-g2" &&
      azurerm_windows_virtual_machine.vm["np01"].secure_boot_enabled &&
      azurerm_windows_virtual_machine.vm["np01"].vtpm_enabled &&
    azurerm_windows_virtual_machine.vm["np01"].automatic_updates_enabled)
    error_message = "Windows deployment must use Windows 2022 Gen2 with Trusted Launch and OS patching."
  }
}

run "production_requires_bootstrap" {
  command = plan
  variables { require_windows_runtime = true }
  expect_failures = [terraform_data.windows_runtime_contract]
}

run "windows_bootstrap_is_secret_reference_only" {
  command = plan
  variables {
    require_windows_runtime = false # Single-replica unit fixture, not production acceptance.
    windows_bootstrap = {
      np01 = {
        cloudflared_version = "2025.4.0"
        binary_sha256       = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        key_vault_id        = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/secrets-rg/providers/Microsoft.KeyVault/vaults/connector-vault"
        key_vault_uri       = "https://connector-vault.vault.azure.net"
        token_secret_name   = "cloudflare-nonprod-token"
        rollout_revision    = "np01-initial"
      }
    }
  }
  assert {
    condition = (length(azurerm_virtual_machine_run_command.cloudflared) == 1 &&
    endswith(azurerm_role_assignment.tunnel_token_reader["np01"].scope, "/secrets/cloudflare-nonprod-token"))
    error_message = "Bootstrap must be installed and secret reader permission scoped to the named secret."
  }
}

run "windows_password_is_required" {
  command = plan
  variables { admin_passwords = {} }
  expect_failures = [terraform_data.connector_contract]
}
