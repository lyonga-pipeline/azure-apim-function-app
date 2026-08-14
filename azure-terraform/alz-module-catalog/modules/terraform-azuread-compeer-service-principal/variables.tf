variable "client_id" {
  description = "The client ID of the application."
  type        = string
}

variable "account_enabled" {
  description = "Whether the service principal account is enabled."
  type        = bool
  default     = true
}

variable "alternative_names" {
  description = "A set of alternative names, used to retrieve service principals by subscription, identify resource group and full resource ids for managed identities."
  type        = list(string)
  default     = []
}

variable "app_role_assignment_required" {
  description = "Whether this service principal requires an app role assignment to a user or group before Azure AD will issue a user or access token to the application."
  type        = bool
  default     = false
}

variable "description" {
  description = "A description of the service principal provided for internal end-users."
  type        = string
  default     = ""
}

variable "login_url" {
  description = "The URL where the service provider redirects the user to Azure AD to authenticate. Azure AD uses the URL to launch the application from Microsoft 365 or the Azure AD My Apps. When blank, Azure AD performs IdP-initiated sign-on for applications configured with SAML-based single sign-on.."
  type        = string
  default     = ""
}

variable "notes" {
  description = "A free text field to capture information about the service principal, typically used for operational purposes."
  type        = string
  default     = ""
}

variable "notification_email_addresses" {
  description = "A free text field to capture information about the service principal, typically used for operational purposes."
  type        = list(string)
  default     = []
}

variable "owners" {
  description = "A set of object IDs of principals that will be granted ownership of the service principal. Supported object types are users or service principals. By default, no owners are assigned."
  type        = list(string)
  default     = []
}

variable "preferred_single_sign_on_mode" {
  description = "The preferred single sign-on mode."
  type        = string
  default     = ""

  validation {
    condition     = contains(["oidc", "password", "saml", "notSupported", ""], var.preferred_single_sign_on_mode)
    error_message = "The preferred_single_sign_on_mode must be one of: oidc, password, saml, notSupported, or an empty string."
  }
}

variable "tags" {
  description = "Tags for the service principal."
  type        = list(string)
  default     = []
}

/*
Caveats of use_existing
Enabling this behaviour is useful for managing existing service principals that may already be 
installed in your tenant for Microsoft-published APIs, as it allows you to make changes where 
permitted, and then also reference them in your Terraform configuration. However, the behaviour 
of delete operations is also affected - when use_existing is true, Terraform will still attempt 
to delete the service principal on destroy, although it will not raise an error if the deletion 
fails (as it often the case for first-party Microsoft applications).
*/
variable "use_existing" {
  description = "Whether to use an existing service principal if it exists."
  type        = bool
  default     = true
}

/*
NOTE:
Cannot be used together with the tags property.

Features and Tags:
Features are configured for a service principal using tags, and are provided as a shortcut to set 
the corresponding magic tag value for each feature. You cannot configure feature_tags and tags for 
a service principal at the same time, so if you need to assign additional custom tags it's 
recommended to use the tags property instead. Any tags configured for the linked application 
will propagate to this service principal.
*/
variable "feature_tags" {
  description = "Configuration for feature tags."
  type = list(object({
    custom_single_sign_on = optional(bool)
    enterprise            = optional(bool)
    gallery               = optional(bool)
    hide                  = optional(bool)
  }))
  default = []
}

variable "saml_single_sign_on" {
  description = "Configuration for SAML single sign-on."
  type = list(object({
    relay_state = optional(string)
  }))
  default = []
}