resource "azurerm_virtual_machine_extension" "join-domain" {
  count                      = var.enable_ad_join ? 1 : 0
  name                       = "join-domain"
  virtual_machine_id         = azurerm_windows_virtual_machine.windows_vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true
  tags                       = { "ResourceName" = "join-domain" }

  settings = <<SETTINGS
    {
        "Name": "${var.active_directory_domain}",
        "OUPath": "${var.ou_path != null ? var.ou_path : ""}",
        "User": "${var.active_directory_username}@${var.active_directory_domain}",
        "Restart": "true",
        "Options": "3"
    }
SETTINGS

  protected_settings = <<SETTINGS
    {
        "Password": "${var.active_directory_password}"
    }
SETTINGS
}