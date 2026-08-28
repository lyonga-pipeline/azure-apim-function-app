variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "centralus"
}

variable "environment" {
  type = string
}

variable "prefix" {
  type    = string
  default = "cmp"
}

variable "enable_telemetry" {
  type    = bool
  default = true
}

variable "enable_resource_locks" {
  type    = bool
  default = false
}

variable "log_retention_days" {
  type    = number
  default = 90

  validation {
    condition     = var.log_retention_days >= 30
    error_message = "Log retention must be at least 30 days."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "key_vault_admin_principal_ids" {
  type    = set(string)
  default = []
}

variable "platform_private_endpoint_subnet_id" {
  description = "Subnet ID used for platform Key Vault and Storage private endpoints. Null skips private endpoint creation in this root."
  type        = string
  default     = null
}

variable "key_vault_private_dns_zone_ids" {
  description = "Private DNS zone IDs for privatelink.vaultcore.azure.net."
  type        = list(string)
  default     = []
}

variable "platform_storage_private_endpoints" {
  description = "Storage private endpoints keyed by endpoint purpose, usually blob/file/queue/table."
  type = map(object({
    subresource_name     = string
    private_dns_zone_ids = list(string)
  }))
  default = {}
}

variable "sentinel_enabled" {
  description = "Set true to onboard the central Log Analytics workspace to Microsoft Sentinel."
  type        = bool
  default     = true
}

variable "sentinel_data_connectors" {
  description = "Approved Sentinel connector contract for SEC-02."
  type = map(object({
    connector_type = string
    source         = optional(string)
    enabled        = optional(bool, false)
    notes          = optional(string)
  }))
  default = {}
}

variable "defender_enabled" {
  description = "Set true to deploy Defender for Cloud subscription posture. Keep false until SOC/cost approval."
  type        = bool
  default     = false
}

variable "defender_plans" {
  description = "Defender for Cloud plans keyed by logical plan name."
  type = map(object({
    resource_type = string
    tier          = optional(string, "Standard")
    subplan       = optional(string)
    extensions = optional(map(object({
      name                            = string
      additional_extension_properties = optional(map(string))
    })), {})
  }))
  default = {}
}

variable "security_contact" {
  description = "Defender for Cloud security contact."
  type = object({
    name                = optional(string, "default")
    email               = string
    phone               = optional(string)
    alert_notifications = optional(bool, true)
    alerts_to_admins    = optional(bool, true)
  })
  default = null
}

variable "security_center_settings" {
  description = "Security Center settings keyed by setting name."
  type = map(object({
    enabled = bool
  }))
  default = {}
}

variable "soc_posture_contract" {
  description = "No-cost target-state record for Defender/Sentinel posture."
  type = object({
    defender_standard_enabled     = optional(bool, false)
    sentinel_enabled              = optional(bool, false)
    data_collection_rules_enabled = optional(bool, false)
    security_contact_enabled      = optional(bool, false)
    notes                         = optional(string)
  })
  default = {}
}
