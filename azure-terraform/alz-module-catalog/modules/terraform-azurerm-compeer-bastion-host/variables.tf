variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "bastion_subnet_id" {
  type = string
}

variable "sku" {
  type    = string
  default = "Standard"
}

variable "copy_paste_enabled" {
  type    = bool
  default = true
}

variable "file_copy_enabled" {
  type    = bool
  default = false
}

variable "ip_connect_enabled" {
  type    = bool
  default = false
}

variable "shareable_link_enabled" {
  type    = bool
  default = false
}

variable "tunneling_enabled" {
  type    = bool
  default = true
}

variable "scale_units" {
  type    = number
  default = 2
}

variable "public_ip_zones" {
  type        = list(string)
  default     = ["1", "2", "3"]
  description = "Availability zones for the Bastion public IP. Use null only in regions that do not support zones."
}

variable "diagnostic_settings" {
  type = map(object({
    log_analytics_workspace_id     = optional(string)
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    logs                           = optional(list(string), ["BastionAuditLogs"])
    metrics                        = optional(list(string), ["AllMetrics"])
  }))
  default     = {}
  description = "Diagnostic settings for Bastion audit logs and metrics."
}

variable "tags" {
  type    = map(string)
  default = {}
}
