variable "display_name" {
  description = "The display name for the group."
  type        = string
}

variable "security_enabled" {
  description = "Whether the group is a security group for controlling access."
  type        = bool
  default     = true
}

variable "mail_enabled" {
  description = "Whether the group is a mail-enabled."
  type        = bool
  default     = null
}

variable "description" {
  description = "The description for the group."
  type        = string
  default     = null
}

variable "administrative_unit_ids" {
  description = "The object IDs of administrative units in which the group is a member. If specified, new groups will be created in the scope of the first administrative unit and added to the others. If empty, new groups will be created at the tenant level."
  type        = set(string)
  default     = null
}

variable "assignable_to_role" {
  description = "Indicates whether this group can be assigned to an Azure Active Directory role."
  type        = bool
  default     = null
}

variable "auto_subscribe_new_members" {
  description = "Indicates whether new members added to the group will be auto-subscribed to receive email notifications."
  type        = bool
  default     = null
}

variable "behaviors" {
  description = "A set of behaviors for a Microsoft 365 group."
  type        = set(string)
  default     = null
}

variable "external_senders_allowed" {
  description = "Indicates whether people external to the organization can send messages to the group."
  type        = bool
  default     = null
}

variable "hide_from_address_lists" {
  description = "Indicates whether the group is displayed in certain parts of the Outlook user interface."
  type        = bool
  default     = null
}

variable "hide_from_outlook_clients" {
  description = "Indicates whether the group is displayed in Outlook clients."
  type        = bool
  default     = null
}

variable "mail_nickname" {
  description = "The mail alias for the group."
  type        = string
  default     = null
}

variable "members" {
  description = "A set of members who should be present in this group."
  type        = list(string)
  default     = null
}

variable "onpremises_group_type" {
  description = "The on-premises group type that the AAD group will be written as."
  type        = string
  default     = null
}

variable "owners" {
  description = "A set of object IDs of principals that will be granted ownership of the group."
  type        = set(string)
  default     = null
}

variable "prevent_duplicate_names" {
  description = "Return an error if an existing group is found with the same name."
  type        = bool
  default     = null
}

variable "provisioning_options" {
  description = "A set of provisioning options for a Microsoft 365 group."
  type        = set(string)
  default     = null
}

variable "theme" {
  description = "The colour theme for a Microsoft 365 group."
  type        = string
  default     = null
}

variable "types" {
  description = "A set of group types to configure for the group."
  type        = set(string)
  default     = null
}

variable "visibility" {
  description = "The group join policy and group content visibility."
  type        = string
  default     = null

  validation {
    condition     = var.visibility == null ? true : contains(["Private", "Public", "Hiddenmembership"], var.visibility)
    error_message = "visibility must be Private, Public or Hiddenmembership."
  }
}

variable "writeback_enabled" {
  description = "Whether the group will be written back to the on-premises AD."
  type        = bool
  default     = null
}

variable "dynamic_membership" {
  description = "Configuration for the dynamic_membership block."
  type = object({
    enabled = bool
    rule    = string
  })
  default = null
}
