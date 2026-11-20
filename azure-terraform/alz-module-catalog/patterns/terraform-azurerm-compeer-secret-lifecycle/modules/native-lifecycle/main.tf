terraform {
  required_version = ">= 1.11.4, < 2.0.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">= 4.81.0, < 5.0.0" }
  }
}
variable "vault_id" { type = string }
variable "keys" {
  description = "Only new or explicitly imported keys. Never recreate existing encryption keys. Historical versions are not deleted or disabled."
  type = map(object({ name = string, key_type = optional(string, "RSA"), key_size = optional(number, 3072),
    key_opts = optional(list(string), ["encrypt", "decrypt", "wrapKey", "unwrapKey"]),
  expire_after = optional(string, "P2Y"), rotate_after = optional(string, "P1Y"), notify_before_expiry = optional(string, "P30D") }))
  default = {}
}
variable "certificates" {
  description = "New or imported CA-integrated certificates only. Issuer integration must already exist; endpoint deployment/adoption is not accomplished by renewal."
  type = map(object({ name = string, issuer_name = string, subject = string, dns_names = list(string),
  validity_months = number, renew_lifetime_percentage = optional(number, 66), exportable = optional(bool, false) }))
  default = {}
  validation {
    condition = alltrue([for cert in values(var.certificates) :
      !contains(["Self", "Unknown"], cert.issuer_name) && cert.renew_lifetime_percentage > 0 && cert.renew_lifetime_percentage < 100
    ])
    error_message = "Automatic CA renewal requires an existing integrated issuer, not Self/Unknown."
  }
}
resource "azurerm_key_vault_key" "key" {
  for_each     = var.keys
  name         = each.value.name
  key_vault_id = var.vault_id
  key_type     = each.value.key_type
  key_size     = each.value.key_size
  key_opts     = each.value.key_opts
  rotation_policy {
    automatic { time_after_creation = each.value.rotate_after }
    expire_after         = each.value.expire_after
    notify_before_expiry = each.value.notify_before_expiry
  }
  lifecycle { prevent_destroy = true }
}
resource "azurerm_key_vault_certificate" "certificate" {
  for_each     = var.certificates
  name         = each.value.name
  key_vault_id = var.vault_id
  certificate_policy {
    issuer_parameters { name = each.value.issuer_name }
    key_properties {
      exportable = each.value.exportable
      key_type   = "RSA"
      key_size   = 3072
      reuse_key  = false
    }
    secret_properties { content_type = "application/x-pkcs12" }
    x509_certificate_properties {
      subject            = each.value.subject
      validity_in_months = each.value.validity_months
      key_usage          = ["digitalSignature", "keyEncipherment"]
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]
      subject_alternative_names { dns_names = each.value.dns_names }
    }
    lifetime_action {
      action { action_type = "AutoRenew" }
      trigger { lifetime_percentage = each.value.renew_lifetime_percentage }
    }
  }
  lifecycle { prevent_destroy = true }
}
output "key_ids" { value = { for k, v in azurerm_key_vault_key.key : k => v.id } }
output "certificate_ids" { value = { for k, v in azurerm_key_vault_certificate.certificate : k => v.id } }
