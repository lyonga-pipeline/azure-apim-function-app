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

variable "kerberos_enabled" {
  type    = bool
  default = false
}

variable "session_recording_enabled" {
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

variable "public_ip_id" {
  type        = string
  default     = null
  description = "Existing Public IP ID to use for Bastion. When null, this module creates a Public IP."
}

variable "public_ip" {
  type = object({
    name                    = optional(string)
    allocation_method       = optional(string, "Static")
    sku                     = optional(string, "Standard")
    sku_tier                = optional(string, "Regional")
    domain_name_label       = optional(string)
    ip_version              = optional(string, "IPv4")
    idle_timeout_in_minutes = optional(number, 4)
    public_ip_prefix_id     = optional(string)
    reverse_fqdn            = optional(string)
    zones                   = optional(list(string))
    tags                    = optional(map(string), {})
  })
  default     = {}
  description = "Public IP settings when the module creates the Bastion Public IP."
}

variable "zones" {
  type        = list(string)
  default     = null
  description = "Optional availability zones for the Bastion host."
}

variable "diagnostic_settings" {
  type = map(object({
    log_analytics_workspace_id     = optional(string)
    log_analytics_destination_type = optional(string)
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    logs                           = optional(list(string), ["BastionAuditLogs"])
    metrics                        = optional(list(string), ["AllMetrics"])
  }))
  default     = {}
  description = "Diagnostic settings for Bastion audit logs and metrics."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    update = optional(string)
    read   = optional(string)
    delete = optional(string)
  })
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
