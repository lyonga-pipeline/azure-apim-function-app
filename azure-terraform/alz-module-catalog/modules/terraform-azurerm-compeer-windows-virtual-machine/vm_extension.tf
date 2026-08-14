resource "azurerm_virtual_machine_extension" "join-domain" {
  count                      = var.enable_ad_join ? 1 : 0
  name                       = "join-domain"
  virtual_machine_id         = azurerm_windows_virtual_machine.windows_vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true
  tags                       = merge({ "ResourceName" = "join-domain" }, var.ext_tags, )

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

data "template_file" "disk_partition_ps1" {
  template = file("${abspath(path.root)}/${path.module}/templates/formatDisk.ps1.tpl")
  vars = {
    drive_letters = local.drive_letter
    drive_label   = local.drive_label
  }
}

resource "azurerm_virtual_machine_extension" "formatDisk" {
  count                = var.enable_disk_extension ? 1 : 0
  name                 = "vm-disk-init-ext"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
          "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.disk_partition_ps1.rendered)}')) | Out-File -filepath FormatDisk.ps1\" && powershell -ExecutionPolicy Unrestricted -File FormatDisk.ps1"
    }
SETTINGS
  depends_on = [
    azurerm_windows_virtual_machine.windows_vm,
    azurerm_virtual_machine_data_disk_attachment.name
  ]
}
