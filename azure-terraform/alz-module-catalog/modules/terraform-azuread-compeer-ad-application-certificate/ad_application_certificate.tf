resource "azuread_application_certificate" "ad_application_certificate" {
  application_object_id = var.application_object_id
  encoding = var.encoding
  end_date = var.end_date
  end_date_relative = var.end_date_relative
  key_id = var.key_id
  start_date = var.start_date
  type = var.type
  value = var.value
}