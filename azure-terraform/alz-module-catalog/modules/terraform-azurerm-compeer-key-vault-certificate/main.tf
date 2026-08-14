resource "azurerm_key_vault_certificate" "this" {
  for_each     = var.certificates
  name         = each.key
  key_vault_id = var.key_vault_id
  tags         = merge(var.tags, try(each.value.tags, {}))

  certificate_policy {
    issuer_parameters {
      name = each.value.issuer_name
    }

    key_properties {
      exportable = try(each.value.exportable, true)
      key_size   = try(each.value.key_size, 2048)
      key_type   = try(each.value.key_type, "RSA")
      reuse_key  = try(each.value.reuse_key, true)
    }

    secret_properties {
      content_type = try(each.value.content_type, "application/x-pkcs12")
    }

    x509_certificate_properties {
      subject            = each.value.subject
      validity_in_months = try(each.value.validity_in_months, 12)
      key_usage          = try(each.value.key_usage, ["digitalSignature", "keyEncipherment"])

      dynamic "subject_alternative_names" {
        for_each = try(each.value.subject_alternative_names, null) == null ? [] : [each.value.subject_alternative_names]
        content {
          dns_names = try(subject_alternative_names.value.dns_names, null)
          emails    = try(subject_alternative_names.value.emails, null)
          upns      = try(subject_alternative_names.value.upns, null)
        }
      }
    }
  }
}
