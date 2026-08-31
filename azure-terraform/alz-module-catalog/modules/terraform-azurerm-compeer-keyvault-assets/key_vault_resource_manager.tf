# Bulk Key Vault data-plane assets (secrets, keys, certificates) for one vault.
# For assets with independent rotation/ownership lifecycles, use the dedicated
# key-vault-secret / key-vault-key / key-vault-certificate modules instead.

resource "azurerm_key_vault_secret" "secret" {
  for_each = var.secrets

  name            = coalesce(try(each.value.name, null), each.key)
  value           = each.value.value
  key_vault_id    = var.key_vault_id
  content_type    = try(each.value.content_type, null)
  not_before_date = try(each.value.not_before_date, null)
  expiration_date = try(each.value.expiration_date, null)
  tags            = try(each.value.tags, {})
}

resource "azurerm_key_vault_key" "key" {
  for_each = var.keys

  name            = coalesce(try(each.value.name, null), each.key)
  key_vault_id    = var.key_vault_id
  key_type        = each.value.key_type
  key_size        = try(each.value.key_size, null)
  curve           = try(each.value.curve, null)
  key_opts        = each.value.key_opts
  not_before_date = try(each.value.not_before_date, null)
  expiration_date = try(each.value.expiration_date, null)
  tags            = try(each.value.tags, {})

  dynamic "rotation_policy" {
    for_each = try(each.value.rotation_policy, null) == null ? [] : [each.value.rotation_policy]
    content {
      expire_after         = try(rotation_policy.value.expire_after, null)
      notify_before_expiry = try(rotation_policy.value.notify_before_expiry, null)
      dynamic "automatic" {
        for_each = try(rotation_policy.value.automatic, null) == null ? [] : [rotation_policy.value.automatic]
        content {
          time_after_creation = try(automatic.value.time_after_creation, null)
          time_before_expiry  = try(automatic.value.time_before_expiry, null)
        }
      }
    }
  }
}

resource "azurerm_key_vault_certificate" "certificate" {
  for_each = var.certificates

  name         = coalesce(try(each.value.name, null), each.key)
  key_vault_id = var.key_vault_id
  tags         = try(each.value.tags, {})

  dynamic "certificate" {
    for_each = try(each.value.import, null) == null ? [] : [each.value.import]
    content {
      contents = certificate.value.contents
      password = try(certificate.value.password, null)
    }
  }

  dynamic "certificate_policy" {
    for_each = try(each.value.policy, null) == null ? [] : [each.value.policy]
    content {
      issuer_parameters {
        name = certificate_policy.value.issuer_parameters.name
      }

      key_properties {
        curve      = try(certificate_policy.value.key_properties.curve, null)
        exportable = certificate_policy.value.key_properties.exportable
        key_size   = try(certificate_policy.value.key_properties.key_size, null)
        key_type   = certificate_policy.value.key_properties.key_type
        reuse_key  = certificate_policy.value.key_properties.reuse_key
      }

      dynamic "lifetime_action" {
        for_each = try(certificate_policy.value.lifetime_actions, [])
        content {
          action { action_type = lifetime_action.value.action_type }
          trigger {
            days_before_expiry  = try(lifetime_action.value.days_before_expiry, null)
            lifetime_percentage = try(lifetime_action.value.lifetime_percentage, null)
          }
        }
      }

      secret_properties {
        content_type = certificate_policy.value.secret_properties.content_type
      }

      dynamic "x509_certificate_properties" {
        for_each = try(certificate_policy.value.x509_certificate_properties, null) == null ? [] : [certificate_policy.value.x509_certificate_properties]
        content {
          extended_key_usage = try(x509_certificate_properties.value.extended_key_usage, null)
          key_usage          = x509_certificate_properties.value.key_usage
          subject            = x509_certificate_properties.value.subject
          validity_in_months = x509_certificate_properties.value.validity_in_months

          dynamic "subject_alternative_names" {
            for_each = try(x509_certificate_properties.value.subject_alternative_names, null) == null ? [] : [x509_certificate_properties.value.subject_alternative_names]
            content {
              dns_names = try(subject_alternative_names.value.dns_names, null)
              emails    = try(subject_alternative_names.value.emails, null)
              upns      = try(subject_alternative_names.value.upns, null)
            }
          }
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = (try(each.value.import, null) == null) != (try(each.value.policy, null) == null)
      error_message = "Each certificate must configure exactly one of import or policy."
    }
  }
}
