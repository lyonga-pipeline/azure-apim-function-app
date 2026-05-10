variable "key_vault_id" { type = string }
variable "certificates" {
  type = map(object({
    issuer_name        = string
    subject            = string
    exportable         = optional(bool, true)
    key_size           = optional(number, 2048)
    key_type           = optional(string, "RSA")
    reuse_key          = optional(bool, true)
    content_type       = optional(string, "application/x-pkcs12")
    validity_in_months = optional(number, 12)
    key_usage          = optional(list(string), ["digitalSignature", "keyEncipherment"])
    subject_alternative_names = optional(object({
      dns_names = optional(list(string))
      emails    = optional(list(string))
      upns      = optional(list(string))
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}
variable "tags" {
  type    = map(string)
  default = {}
}
