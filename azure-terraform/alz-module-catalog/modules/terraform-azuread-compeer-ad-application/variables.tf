variable "display_name" {
  description = "The display name for the application."
  type        = string
}

variable "description" {
  description = "A description of the application, as shown to end users."
  type        = string
  default     = null
}

variable "device_only_auth_enabled" {
  description = "Specifies whether this application supports device authentication without a user."
  type        = bool
  default     = false
}

variable "fallback_public_client_enabled" {
  description = "Specifies whether the application is a public client."
  type        = bool
  default     = false
}

variable "group_membership_claims" {
  description = "Configures the groups claim issued in a user or OAuth 2.0 access token that the app expects."
  type        = set(string)
  default     = []

  validation {
    condition     = (length(var.group_membership_claims) == 0) || alltrue([for claim in var.group_membership_claims : contains(["None", "SecurityGroup", "DirectoryRole", "ApplicationGroup", "All"], claim)])
    error_message = "The group_membership_claims must be one of: None, SecurityGroup, DirectoryRole, ApplicationGroup, or All."
  }
}

variable "identifier_uris" {
  description = "A set of user-defined URI(s) that uniquely identify an application."
  type        = list(string)
  default     = []
}

variable "logo_image" {
  description = "A raw base64-encoded string representing the application's logo image."
  type        = string
  default     = null
}

variable "marketing_url" {
  description = "URL of the application's marketing page."
  type        = string
  default     = null
}

variable "notes" {
  description = "User-specified notes relevant for the management of the application."
  type        = string
  default     = null
}

variable "oauth2_post_response_required" {
  description = "Specifies whether Azure AD allows POST requests, as opposed to GET requests, as part of OAuth 2.0 token requests."
  type        = bool
  default     = false
}

variable "owners" {
  description = "A set of object IDs of principals that will be granted ownership of the application."
  type        = list(string)
  default     = []
}

variable "prevent_duplicate_names" {
  description = "If true, will return an error if an existing application is found with the same name."
  type        = bool
  default     = false
}

variable "privacy_statement_url" {
  description = "URL of the application's privacy statement."
  type        = string
  default     = null
}

variable "service_management_reference" {
  description = "References application context information from a Service or Asset Management database."
  type        = string
  default     = null
}

variable "sign_in_audience" {
  description = "The Microsoft account types that are supported for the current application."
  type        = string
  default     = null
}

variable "support_url" {
  description = "URL of the application's support page."
  type        = string
  default     = null
}

variable "template_id" {
  description = "Unique ID for a templated application in the Azure AD App Gallery, from which to create the application."
  type        = string
  default     = null
}

variable "terms_of_service_url" {
  description = "URL of the application's terms of service statement."
  type        = string
  default     = null
}

variable "tags" {
  description = "A set of tags to apply to the application for configuring specific behaviours."
  type        = list(string)
  default     = []
}

variable "api" {
  description = "API configuration for the Azure AD application."
  type = list(object({
    known_client_applications = list(string)
    mapped_claims_enabled     = bool
    oauth2_permission_scope = list(object({
      admin_consent_description  = string
      admin_consent_display_name = string
      enabled                    = bool
      id                         = string
      type                       = string
      user_consent_description   = string
      user_consent_display_name  = string
      value                      = string
    }))
    requested_access_token_version = number
  }))
  default = []
}

variable "app_role" {
  description = "App Role configuration for the Azure AD application."
  type = list(object({
    allowed_member_types = list(string)
    description          = string
    display_name         = string
    enabled              = bool
    id                   = string
    value                = string
  }))
  default = []
}

variable "optional_claims" {
  description = "Optional Claims configuration for the Azure AD application."
  type = object({
    access_token = list(object({
      additional_properties = list(string)
      essential             = bool
      name                  = string
      source                = string
    }))
    id_token = list(object({
      additional_properties = list(string)
      essential             = bool
      name                  = string
      source                = string
    }))
    saml2_token = list(object({
      additional_properties = list(string)
      essential             = bool
      name                  = string
      source                = string
    }))
  })
  default = {
    access_token = []
    id_token     = []
    saml2_token  = []
  }
}

variable "public_client" {
  description = "Public Client configuration for the Azure AD application."
  type = list(object({
    redirect_uris = list(string)
  }))
  default = []
}

variable "required_resource_access" {
  description = "Configuration for required resource access"
  type = list(object({
    resource_app_id = string
    resource_access = list(object({
      id   = string
      type = string
    }))
  }))
  default = []
}

variable "single_page_application" {
  description = "Configuration for single page application"
  type = object({
    redirect_uris = list(string)
  })
  default = null
}

variable "web" {
  description = "Configuration for web application settings"
  type = object({
    homepage_url  = optional(string)
    logout_url    = optional(string)
    redirect_uris = list(string)
    implicit_grant = object({
      access_token_issuance_enabled = optional(bool)
      id_token_issuance_enabled     = optional(bool)
    })
  })
  default = null
}

variable "client_secret_dispaly_name" {
  description = "A display name for the password. Changing this field forces a new resource to be created."
  type        = string
  default     = null
}

variable "end_date" {
  description = "The end date until which the password is valid, formatted as an RFC3339 date string (e.g. 2018-01-01T01:02:03Z). Changing this field forces a new resource to be created."
  type        = string
  default     = null
}

variable "end_date_relative" {
  description = "A relative duration for which the password is valid until, for example 240h (10 days) or 2400h30m. Changing this field forces a new resource to be created."
  type        = string
  default     = null
}

variable "rotate_when_changed" {
  description = "A map of arbitrary key/value pairs that will force recreation of the password when they change, enabling password rotation based on external conditions such as a rotating timestamp. Changing this forces a new resource to be created."
  type        = map(string)
  default     = {}
}

variable "start_date" {
  description = "The start date from which the password is valid, formatted as an RFC3339 date string (e.g. 2018-01-01T01:02:03Z). If this isn't specified, the current date is used. Changing this field forces a new resource to be created."
  type        = string
  default     = null
}