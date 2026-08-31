variable "key_vault_id" {
  description = "ID of the existing Key Vault that owns these assets."
  type        = string
}

variable "secrets" {
  description = "Secrets keyed by stable caller-controlled logical name. Prefer the dedicated secret module for independent ownership."
  type = map(object({
    name            = optional(string)
    value           = string
    content_type    = optional(string)
    not_before_date = optional(string)
    expiration_date = optional(string)
    tags            = optional(map(string), {})
  }))
  default = {}
}

variable "keys" {
  description = "Keys keyed by stable caller-controlled logical name."
  type = map(object({
    name            = optional(string)
    key_type        = string
    key_size        = optional(number)
    curve           = optional(string)
    key_opts        = list(string)
    not_before_date = optional(string)
    expiration_date = optional(string)
    tags            = optional(map(string), {})
    rotation_policy = optional(object({
      expire_after         = optional(string)
      notify_before_expiry = optional(string)
      automatic = optional(object({
        time_after_creation = optional(string)
        time_before_expiry  = optional(string)
      }))
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for k in values(var.keys) : contains(["RSA", "RSA-HSM", "EC", "EC-HSM"], k.key_type)])
    error_message = "key_type must be one of RSA, RSA-HSM, EC, EC-HSM."
  }
}

variable "certificates" {
  description = "Certificates keyed by stable caller-controlled logical name. Configure exactly one of import or policy per entry."
  type = map(object({
    name = optional(string)
    import = optional(object({
      contents = string
      password = optional(string)
    }))
    policy = optional(object({
      issuer_parameters = object({ name = string })
      key_properties = object({
        curve      = optional(string)
        exportable = bool
        key_size   = optional(number)
        key_type   = string
        reuse_key  = bool
      })
      lifetime_actions = optional(list(object({
        action_type         = string
        days_before_expiry  = optional(number)
        lifetime_percentage = optional(number)
      })), [])
      secret_properties = object({ content_type = string })
      x509_certificate_properties = optional(object({
        extended_key_usage = optional(list(string))
        key_usage          = list(string)
        subject            = string
        validity_in_months = number
        subject_alternative_names = optional(object({
          dns_names = optional(list(string))
          emails    = optional(list(string))
          upns      = optional(list(string))
        }))
      }))
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}
