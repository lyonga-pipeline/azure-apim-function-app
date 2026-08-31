variable "client_id" {
  description = "Application/client ID for the service principal."
  type        = string
}
variable "account_enabled" {
  description = "Whether the service principal account is enabled."
  type        = bool
  default     = true
}
variable "alternative_names" {
  type    = set(string)
  default = []
}
variable "app_role_assignment_required" {
  type    = bool
  default = false
}
variable "description" {
  type    = string
  default = null
}
variable "login_url" {
  type    = string
  default = null
}
variable "notes" {
  type    = string
  default = null
}
variable "notification_email_addresses" {
  type    = set(string)
  default = []
}
variable "owners" {
  description = "Object IDs of principals granted ownership."
  type        = set(string)
  default     = []
}
variable "preferred_single_sign_on_mode" {
  description = "SSO mode: oidc, password, saml, or notSupported."
  type        = string
  default     = null
  validation {
    condition     = var.preferred_single_sign_on_mode == null ? true : contains(["oidc", "password", "saml", "notSupported"], var.preferred_single_sign_on_mode)
    error_message = "preferred_single_sign_on_mode must be null, oidc, password, saml, or notSupported."
  }
}
variable "tags" {
  description = "Tags (mutually exclusive with feature_tags)."
  type        = set(string)
  default     = []
}
variable "feature_tags" {
  type = object({
    custom_single_sign_on = optional(bool)
    enterprise            = optional(bool)
    gallery               = optional(bool)
    hide                  = optional(bool)
  })
  default = null
}
variable "saml_single_sign_on" {
  type    = object({ relay_state = optional(string) })
  default = null
}
