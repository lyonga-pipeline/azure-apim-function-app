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

variable "workload" {
  type = string
}

variable "prefix" {
  type    = string
  default = "cmp"
}

variable "address_space" {
  type = list(string)
}

variable "ipam_pools" {
  description = "Optional explicit AVM IPAM pools. If empty, a convention-based pool ID is generated from the workload name."
  type = list(object({
    id                     = string
    prefix_length          = optional(number)
    number_of_ip_addresses = optional(number)
  }))
  default = []
}

variable "ipam_prefix_length" {
  type    = number
  default = 24
}

variable "subnets" {
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(set(string), [])
  }))
}

variable "hub_vnet_id" {
  type = string
}

variable "firewall_next_hop_ip" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "enable_workload_identity" {
  type    = bool
  default = true
}

variable "workload_identity_name" {
  type    = string
  default = null
}

variable "enable_workload_key_vault" {
  type    = bool
  default = true
}

variable "workload_key_vault_name" {
  type    = string
  default = null
}

variable "workload_key_vault_private_endpoint_subnet_key" {
  type    = string
  default = null
}

variable "workload_key_vault_private_dns_zone_ids" {
  type    = list(string)
  default = []
}

variable "workload_key_vault_additional_role_assignments" {
  description = "Additional Key Vault RBAC assignments. Scope is set to the workload Key Vault."
  type = map(object({
    principal_id                           = string
    role_definition_name                   = optional(string)
    role_definition_id                     = optional(string)
    principal_type                         = optional(string)
    description                            = optional(string)
    condition                              = optional(string)
    condition_version                      = optional(string)
    skip_service_principal_aad_check       = optional(bool)
    delegated_managed_identity_resource_id = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for item in values(var.workload_key_vault_additional_role_assignments) :
      (
        (try(item.role_definition_name, null) != null || try(item.role_definition_id, null) != null) &&
        !(try(item.role_definition_name, null) != null && try(item.role_definition_id, null) != null)
      )
    ])
    error_message = "Each Key Vault assignment must set exactly one of role_definition_name or role_definition_id."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_telemetry" {
  type    = bool
  default = true
}
