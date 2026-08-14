variable "create_secret" {
  description = "Whether to create a secret"
  type        = bool
  default     = false
}

variable "create_key" {
  description = "Whether to create a key"
  type        = bool
  default     = false
}

variable "import_certificate" {
  description = "Whether to import an existing certificate"
  type        = bool
  default     = false
}

variable "generate_certificate" {
  description = "Whether to generate a new certificate"
  type        = bool
  default     = false
}

variable "key_vault_id" {
  description = <<EOT
  "The ID of the Key Vault where the Secret should be created.
  Changing this forces a new resource to be created."
  EOT
  type        = string
}

/*
azurerm_key_vault_secret specific variables
*/
variable "secret_name" {
  description = <<EOT
  "Specifies the name of the Key Vault Secret.
  Changing this forces a new resource to be created."
  EOT
  type        = string
  default     = null
}

/*
Note:
Key Vault strips newlines. To preserve newlines in multi-line secrets try replacing them 
with \n or by base 64 encoding them with replace(file("my_secret_file"), "/\n/", "\n") 
or base64encode(file("my_secret_file")), respectively.
*/
variable "secret_value" {
  description = "Specifies the value of the Key Vault Secret."
  type        = string
  default     = null
}

variable "secret_content_type" {
  description = "Specifies the content type for the Key Vault Secret."
  type        = string
  default     = null
}

variable "secret_tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = null
}

variable "secret_not_before_date" {
  description = "Key not usable before the provided UTC datetime (Y-m-d'T'H:M:S'Z')."
  type        = string
  default     = null
}

variable "secret_expiration_date" {
  description = "Expiration UTC datetime (Y-m-d'T'H:M:S'Z')."
  type        = string
  default     = null
}

variable "secret_lifecycle" {
  description = "Key Vault Secret Lifecycle"
  type = object({
    ignore_changes = list(string)
  })
  default = null
}

/*
azurerm_key_vault_key specific variables
*/
variable "key_name" {
  description = <<EOT
  "Specifies the name of the Key Vault Key. 
  Changing this forces a new resource to be created."
  EOT
  type        = string
  default     = null
}

variable "key_type" {
  description = <<EOT
  "Specifies the Key Type to use for this Key Vault Key.
  Possible values are EC (Elliptic Curve), EC-HSM, RSA and RSA-HSM.
  Changing this forces a new resource to be created."
  EOT
  type        = string
  default     = null
}

variable "key_size" {
  description = <<EOT
  description = "Specifies the Size of the RSA key to create in bytes.
  For example, 1024 or 2048. Note: This field is required if key_type is RSA or RSA-HSM.
  Changing this forces a new resource to be created."
  EOT
  type        = number
  default     = null
}

variable "key_curve" {
  description = <<EOT
  "Specifies the curve to use when creating an EC key.
  Possible values are P-256, P-256K, P-384, and P-521.
  This field will be required in a future release if key_type is EC or EC-HSM.
  The API will default to P-256 if nothing is specified.
  Changing this forces a new resource to be created."
  EOT
  type        = string
  default     = "value"
}

variable "key_opts" {
  description = <<EOT
  A list of JSON web key operations.
  Possible values include: decrypt, encrypt, sign, unwrapKey, verify and wrapKey.
  Please note these values are case sensitive.
  EOT
  type        = list(string)
  default     = null
}

variable "key_not_before_date" {
  description = "Key not usable before the provided UTC datetime (Y-m-d'T'H:M:S'Z')."
  type        = string
  default     = "value"
}

variable "key_expiration_date" {
  description = "Expiration UTC datetime (Y-m-d'T'H:M:S'Z')."
  type        = string
  default     = "value"
}

variable "key_tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default = {
    "name" = "value"
  }
}

variable "key_rotation_policy" {
  description = "The rotation policy settings for the Key Vault Key."
  type = object({
    expire_after         = string
    notify_before_expiry = string
    automatic_rotation = object({
      enabled             = bool
      time_after_creation = string
      time_before_expiry  = string
    })
  })
  default = null # or provide a default object
}

/*
azurerm_key_vault_import_certificate
*/
variable "import_certificate_name" {
  description = <<EOT
  "Specifies the name of the Key Vault Certificate.
  Changing this forces a new resource to be created."
  EOT
  type        = string
  default     = null
}

/*
NOTE:
When creating a Key Vault Certificate, at least one of certificate or certificate_policy is required.
Provide certificate to import an existing certificate, certificate_policy to generate a new certificate.
*/
variable "import_certificate_block" {
  description = "A certificate block as defined below, used to Import an existing certificate."
  type = object({
    contents = string
    password = string
    # Add other attributes as needed
  })
  default = null
}

variable "import_certificate_tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default = {
    "name" = "value"
  }
}

/*
azurerm_key_vault_generate_certificate
*/
variable "certificate_name" {
  description = <<EOT
  "Specifies the name of the Key Vault Certificate.
  Changing this forces a new resource to be created."
  EOT
  type        = string
  default     = null
}

variable "certificate_policy" {
  description = "A certificate_policy block. Changing this forces a new resource to be created."
  type = object({
    issuer_parameters = object({
      name = string
    })
    key_properties = object({
      curve      = optional(string)
      exportable = bool
      key_type   = string
      key_size   = optional(number)
      reuse_key  = bool
    })
    lifetime_action = optional(list(object({
      action = object({
        action_type = string
      })
      trigger = object({
        lifetime_percentage = optional(number)
        days_before_expiry  = optional(number)
      })
    })))
    secret_properties = object({
      content_type = string
    })
    x509_certificate_properties = optional(object({
      extended_key_usage = optional(list(string))
      key_usage          = list(string)
      subject            = string
      subject_alternative_names = optional(object({
        dns_names = optional(list(string))
        emails    = optional(list(string))
        upns      = optional(list(string))
      }))
      validity_in_months = number
    }))
  })
  default = {
    issuer_parameters = {
      name = "value"
    }
    key_properties = {
      curve      = "value" ## Specifies the curve to use when creating an EC key
      exportable = false
      key_type   = "value"
      key_type   = "value"
      reuse_key  = false
    }
    lifetime_action = [{
      action = {
        action_type = "value"
      }
      trigger = {
        lifetime_percentage = 1
        days_before_expiry  = 1
      }
    }]
    secret_properties = {
      content_type = "value"
    }
    x509_certificate_properties = {
      key_usage          = ["value"]
      subject            = "value"
      validity_in_months = 3
    }
  }
}

variable "certificate_tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}
