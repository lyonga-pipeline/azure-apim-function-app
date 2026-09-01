resource "azurerm_key_vault" "keyvault" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = var.tenant_id
  sku_name                        = var.sku_name
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  purge_protection_enabled        = var.purge_protection_enabled
  public_network_access_enabled   = var.public_network_access_enabled
  rbac_authorization_enabled      = var.rbac_authorization_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days

  dynamic "access_policy" {
    for_each = var.rbac_authorization_enabled ? {} : local.access_policies
    content {
      tenant_id               = access_policy.value.tenant_id
      object_id               = access_policy.value.object_id
      application_id          = try(access_policy.value.application_id, null)
      key_permissions         = try(access_policy.value.key_permissions, [])
      secret_permissions      = try(access_policy.value.secret_permissions, [])
      certificate_permissions = try(access_policy.value.certificate_permissions, [])
      storage_permissions     = try(access_policy.value.storage_permissions, [])
    }
  }

  dynamic "network_acls" {
    for_each = var.network_acls == null ? [] : [var.network_acls]
    content {
      bypass                     = network_acls.value.bypass
      default_action             = network_acls.value.default_action
      ip_rules                   = try(network_acls.value.ip_rules, [])
      virtual_network_subnet_ids = try(network_acls.value.virtual_network_subnet_ids, [])
    }
  }

  dynamic "contact" {
    for_each = { for c in var.contacts : c.email => c }
    content {
      email = contact.value.email
      name  = try(contact.value.name, null)
      phone = try(contact.value.phone, null)
    }
  }

  tags = var.tags

  timeouts {
    create = try(var.timeouts.create, null)
    read   = try(var.timeouts.read, null)
    update = try(var.timeouts.update, null)
    delete = try(var.timeouts.delete, null)
  }

  lifecycle {
    precondition {
      condition     = var.rbac_authorization_enabled || length(local.access_policies) > 0
      error_message = "When rbac_authorization_enabled is false, configure at least one access policy (access_policies or access_policies_by_key)."
    }

    # A "public" vault must still be firewalled to an explicit allow-list.
    # Guardrail exception path: pair with an RG carve-out or a policy exemption.
    precondition {
      condition = !var.public_network_access_enabled ? true : (
        var.network_acls != null &&
        var.network_acls.default_action == "Deny" &&
        (
          length(try(var.network_acls.ip_rules, [])) > 0 ||
          length(try(var.network_acls.virtual_network_subnet_ids, [])) > 0
        )
      )
      error_message = "public_network_access_enabled = true requires network_acls with default_action = \"Deny\" and at least one ip_rules / virtual_network_subnet_ids entry."
    }
  }
}
