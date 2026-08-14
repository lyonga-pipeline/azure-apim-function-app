resource "azurerm_virtual_machine_extension" "this" {
  name                       = var.name
  virtual_machine_id         = var.virtual_machine_id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = var.type_handler_version
  auto_upgrade_minor_version = true

  settings = jsonencode({
    Name    = var.domain_name
    OUPath  = var.ou_path
    User    = var.domain_username
    Restart = tostring(var.restart)
    Options = var.join_options
  })

  protected_settings = jsonencode({
    Password = var.domain_password
  })

  lifecycle {
    precondition {
      condition     = length(trimspace(var.domain_name)) > 0
      error_message = "domain_name must not be empty."
    }
  }
}
