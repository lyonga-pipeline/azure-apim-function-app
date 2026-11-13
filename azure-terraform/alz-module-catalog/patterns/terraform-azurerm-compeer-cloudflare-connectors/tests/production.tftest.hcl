# Synthetic references prove the full production contract is satisfiable.
mock_provider "azurerm" {}
variables {
  subscription_id         = "11111111-1111-1111-1111-111111111111"
  location                = "centralus"
  environment             = "prod"
  resource_group          = { name = "platform-cus-prod-cfc-rg" }
  require_windows_runtime = true
  admin_passwords         = { one = "NotAReal!Password2026", two = "NotAReal!Password2026" }
  connectors = {
    one = {
      os_type                = "Windows", name = "cus-prod-cft-01", nic_name = "cus-prod-cft-01-nic", zone = "1"
      subnet_id              = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub/subnets/connectors"
      identity               = { type = "SystemAssigned" }
      source_image_reference = { publisher = "MicrosoftWindowsServer", offer = "WindowsServer", sku = "2022-datacenter-g2", version = "20348.2849.241011" }
    }
    two = {
      os_type                = "Windows", name = "cus-prod-cft-02", nic_name = "cus-prod-cft-02-nic", zone = "2"
      subnet_id              = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub/subnets/connectors"
      identity               = { type = "SystemAssigned" }
      source_image_reference = { publisher = "MicrosoftWindowsServer", offer = "WindowsServer", sku = "2022-datacenter-g2", version = "20348.2849.241011" }
    }
  }
  windows_bootstrap = {
    one = {
      cloudflared_version = "2025.4.0", binary_sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      key_vault_id        = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/secrets-rg/providers/Microsoft.KeyVault/vaults/connector-vault"
      key_vault_uri       = "https://connector-vault.vault.azure.net", token_secret_name = "prod-token", rollout_revision = "one-initial"
    }
    two = {
      cloudflared_version = "2025.4.0", binary_sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      key_vault_id        = "/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/secrets-rg/providers/Microsoft.KeyVault/vaults/connector-vault"
      key_vault_uri       = "https://connector-vault.vault.azure.net", token_secret_name = "prod-token", rollout_revision = "two-initial"
    }
  }
}
run "two_zone_windows_runtime_profile_passes" {
  command = plan
  assert {
    condition     = length(azurerm_virtual_machine_run_command.cloudflared) == 2 && length(azurerm_windows_virtual_machine.vm) == 2
    error_message = "Production profile must compose two Windows replicas with managed bootstrap."
  }
}
