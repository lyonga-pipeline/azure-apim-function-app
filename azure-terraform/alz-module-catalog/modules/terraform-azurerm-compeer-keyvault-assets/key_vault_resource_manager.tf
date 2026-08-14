/**
## Creating Azure Key Vault Secret
*/
resource "azurerm_key_vault_secret" "secret" {
  count           = var.create_secret ? 1 : 0
  name            = var.secret_name
  value           = var.secret_value
  key_vault_id    = var.key_vault_id
  content_type    = var.secret_content_type
  tags            = var.secret_tags
  not_before_date = var.secret_not_before_date
  expiration_date = var.secret_expiration_date

  dynamic "lifecycle" {
    for_each = var.secret_lifecycle != null ? [var.secret_lifecycle] : []
    content{
      ignore_changes = secret_lifecycle.value.ignore_changes
    }
  }
}

/**
## Creating Azure Key Vault Key
*/
resource "azurerm_key_vault_key" "key" {
  count           = var.create_key ? 1 : 0
  name            = var.key_name
  key_vault_id    = var.key_vault_id
  key_type        = var.key_type
  key_size        = var.key_size
  curve           = var.key_curve
  key_opts        = var.key_opts
  not_before_date = var.key_not_before_date
  expiration_date = var.key_expiration_date
  tags            = var.key_tags

  dynamic "rotation_policy" {
    for_each = var.key_rotation_policy != null ? [var.key_rotation_policy] : []

    content {
      expire_after         = rotation_policy.value.expire_after
      notify_before_expiry = rotation_policy.value.notify_before_expiry

      dynamic "automatic" {
        for_each = rotation_policy.value.automatic_rotation != null ? [rotation_policy.value.automatic_rotation] : []

        content {
          time_after_creation = automatic.value.time_after_creation
          time_before_expiry  = automatic.value.time_before_expiry
        }
      }
    }
  }
}

/**
## Creating Azure Key Vault Import Certificate
*/
resource "azurerm_key_vault_certificate" "import_certificate" {
  count        = var.import_certificate ? 1 : 0
  name         = var.import_certificate_name
  key_vault_id = var.key_vault_id

  /**
Please note that filebase64() is a Terraform function that reads a file and encodes its content as base64.
So you should provide the path to the certificate file in contents, not the actual contents of the file.
*/
  dynamic "certificate" {
    for_each = var.import_certificate_block != null ? [var.import_certificate_block] : []

    content {
      contents = filebase64(certificate.value.contents)
      password = certificate.value.password
    }
  }

  tags = var.import_certificate_tags
}

/**
## Creating Azure Key Vault Generate Certificate
*/
resource "azurerm_key_vault_certificate" "generate_certificate" {
  count        = var.generate_certificate ? 1 : 0
  name         = var.certificate_name
  key_vault_id = var.key_vault_id
  certificate_policy {
    dynamic "issuer_parameters" {
      for_each = [var.certificate_policy.issuer_parameters]
      content {
        name = issuer_parameters.value.name
      }
    }
    dynamic "key_properties" {
      for_each = [var.certificate_policy.key_properties]
      content {
        curve      = key_properties.value.curve ## Specifies the curve to use when creating an EC key
        exportable = key_properties.value.exportable
        key_size   = key_properties.value.key_size
        key_type   = key_properties.value.key_type
        reuse_key  = key_properties.value.reuse_key
      }
    }
    dynamic "lifetime_action" {
      for_each = var.certificate_policy.lifetime_action != null ? var.certificate_policy.lifetime_action : []
      content {
        action {
          action_type = lifetime_action.value.action.action_type
        }
        trigger {
          days_before_expiry = lifetime_action.value.trigger.days_before_expiry
        }
      }
    }
    dynamic "secret_properties" {
      for_each = [var.certificate_policy.secret_properties]
      content {
        content_type = secret_properties.value.content_type
      }
    }
    dynamic "x509_certificate_properties" {
      for_each = [var.certificate_policy.x509_certificate_properties] != null ? [var.certificate_policy.x509_certificate_properties] : []
      content {
        extended_key_usage = x509_certificate_properties.value.extended_key_usage
        key_usage          = x509_certificate_properties.value.key_usage
        subject            = x509_certificate_properties.value.subject
        validity_in_months = x509_certificate_properties.value.validity_in_months
        dynamic "subject_alternative_names" {
          for_each = x509_certificate_properties.value.subject_alternative_names != null ? [x509_certificate_properties.value.subject_alternative_names] : []
          content {
            dns_names = subject_alternative_names.value.dns_names != null ? subject_alternative_names.value.dns_names : []
            emails    = subject_alternative_names.value.emails != null ? subject_alternative_names.value.emails : []
            upns      = subject_alternative_names.value.upns != null ? subject_alternative_names.value.upns : []
          }
        }
      }
    }
  }
  tags = var.certificate_tags
}
