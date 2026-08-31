locals {
  # Accept either the azuread_application resource ID (/applications/{object-id})
  # or a bare application object ID for backward compatibility.
  application_id = try(coalesce(
    var.application_id,
    var.application_object_id != null ? "/applications/${var.application_object_id}" : null,
  ), null)
}

resource "azuread_application_certificate" "ad_application_certificate" {
  application_id    = local.application_id
  encoding          = var.encoding
  end_date          = var.end_date
  end_date_relative = var.end_date_relative
  key_id            = var.key_id
  start_date        = var.start_date
  type              = var.type
  value             = var.value

  lifecycle {
    precondition {
      condition     = local.application_id != null
      error_message = "Set application_id (preferred) or application_object_id."
    }
  }
}
