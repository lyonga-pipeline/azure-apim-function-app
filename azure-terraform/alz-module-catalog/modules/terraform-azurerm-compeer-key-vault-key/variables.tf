variable "key_vault_id" { type = string }
variable "keys" {
  type = map(object({
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
    condition = alltrue([
      for key in values(var.keys) :
      contains(["EC", "EC-HSM", "RSA", "RSA-HSM"], key.key_type)
    ])
    error_message = "Each key.key_type must be EC, EC-HSM, RSA, or RSA-HSM."
  }

  validation {
    condition = alltrue([
      for key in values(var.keys) :
      alltrue([
        for key_opt in key.key_opts :
        contains(["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"], key_opt)
      ])
    ])
    error_message = "Each key_opts value must be one of decrypt, encrypt, sign, unwrapKey, verify, or wrapKey."
  }
}
variable "tags" {
  type    = map(string)
  default = {}
}
