resource "azurerm_mssql_server" "this" {
  name                                         = var.name
  resource_group_name                          = var.resource_group_name
  location                                     = var.location
  version                                      = var.server_version
  administrator_login                          = var.azuread_authentication_only ? null : var.administrator_login
  administrator_login_password                 = var.azuread_authentication_only ? null : var.administrator_login_password
  minimum_tls_version                          = var.minimum_tls_version
  connection_policy                            = var.connection_policy
  public_network_access_enabled                = var.public_network_access_enabled
  outbound_network_restriction_enabled         = var.outbound_network_restriction_enabled
  express_vulnerability_assessment_enabled     = var.express_vulnerability_assessment_enabled
  primary_user_assigned_identity_id            = var.primary_user_assigned_identity_id
  transparent_data_encryption_key_vault_key_id = var.transparent_data_encryption_key_vault_key_id
  tags                                         = var.tags

  dynamic "azuread_administrator" {
    for_each = var.azuread_administrator == null ? [] : [var.azuread_administrator]
    content {
      login_username              = azuread_administrator.value.login_username
      object_id                   = azuread_administrator.value.object_id
      azuread_authentication_only = var.azuread_authentication_only
    }
  }

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  lifecycle {
    precondition {
      condition     = !var.azuread_authentication_only || var.azuread_administrator != null
      error_message = "azuread_administrator must be set when azuread_authentication_only is true."
    }
    precondition {
      condition = (
        var.azuread_authentication_only ||
        (
          var.administrator_login != null &&
          var.administrator_login_password != null
        )
      )
      error_message = "administrator_login and administrator_login_password must be set when azuread_authentication_only is false."
    }
  }
}
