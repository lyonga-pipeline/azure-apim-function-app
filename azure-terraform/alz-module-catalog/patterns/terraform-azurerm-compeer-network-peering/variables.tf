variable "tenant_id" {
  type        = string
  description = "Azure tenant ID for the hub and spoke subscriptions. Leave null when HCP Terraform Azure dynamic credentials already provide the tenant."
  default     = null
  nullable    = true

  validation {
    condition     = var.tenant_id == null || var.tenant_id == "" || var.tenant_id != "00000000-0000-0000-0000-000000000000"
    error_message = "tenant_id must be unset, blank, or a real Azure tenant ID. Do not use the all-zero placeholder from the example file."
  }
}

variable "hub_subscription_id" {
  type        = string
  description = "Subscription ID that contains the hub VNet and shared Private DNS zones."
}

variable "spoke_subscription_id" {
  type        = string
  description = "Subscription ID that contains the workload spoke VNet."
}

variable "use_tfe_outputs" {
  type        = bool
  description = "Read hub and spoke attachment values from upstream HCP Terraform workspace outputs."
  default     = true
}

variable "tfe_organization" {
  type        = string
  description = "HCP Terraform organization that contains the producer workspaces."
  default     = "lyonga-org"
}

variable "platform_connectivity_workspace_name" {
  type        = string
  description = "Workspace name that publishes hub VNet and shared Private DNS outputs."
  default     = "platform-connectivity"
}

variable "workload_spoke_workspace_name" {
  type        = string
  description = "Workspace name that publishes the workload spoke VNet outputs."
  default     = "workload-spoke"
}

variable "hub_resource_group_name" {
  type        = string
  description = "Resource group name that contains the hub VNet."
  default     = null
  nullable    = true
}

variable "hub_virtual_network_name" {
  type        = string
  description = "Hub virtual network name."
  default     = null
  nullable    = true
}

variable "hub_virtual_network_id" {
  type        = string
  description = "Hub virtual network resource ID."
  default     = null
  nullable    = true
}

variable "spoke_resource_group_name" {
  type        = string
  description = "Resource group name that contains the spoke VNet."
  default     = null
  nullable    = true
}

variable "spoke_virtual_network_name" {
  type        = string
  description = "Spoke virtual network name."
  default     = null
  nullable    = true
}

variable "spoke_virtual_network_id" {
  type        = string
  description = "Spoke virtual network resource ID."
  default     = null
  nullable    = true
}

variable "peering_name_prefix" {
  type        = string
  description = "Stable name prefix for the two peering resources."
  default     = "online-banking-np1"
}

variable "hub_to_spoke" {
  type = object({
    allow_forwarded_traffic      = optional(bool, true)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
    allow_virtual_network_access = optional(bool, true)
  })
  description = "Hub-to-spoke peering flags. Enable allow_gateway_transit only when the hub owns the gateway."
  default     = {}
}

variable "spoke_to_hub" {
  type = object({
    allow_forwarded_traffic      = optional(bool, true)
    allow_gateway_transit        = optional(bool, false)
    use_remote_gateways          = optional(bool, false)
    allow_virtual_network_access = optional(bool, true)
  })
  description = "Spoke-to-hub peering flags. Enable use_remote_gateways only when the hub peering has gateway transit enabled."
  default     = {}
}

variable "private_dns_zone_resource_group_name" {
  type        = string
  description = "Default resource group name for shared Private DNS zones."
  default     = null
}

variable "private_dns_zones" {
  type = map(object({
    name                  = string
    resource_group_name   = optional(string)
    registration_enabled  = optional(bool, false)
    link_name             = optional(string)
    link_to_spoke_enabled = optional(bool, true)
  }))
  description = "Shared Private DNS zones to link to the spoke VNet. Values usually come from platform-connectivity outputs."
  default = {
    app_service = {
      name = "privatelink.azurewebsites.net"
    }
    key_vault = {
      name = "privatelink.vaultcore.azure.net"
    }
    storage_blob = {
      name = "privatelink.blob.core.windows.net"
    }
    storage_queue = {
      name = "privatelink.queue.core.windows.net"
    }
    storage_file = {
      name = "privatelink.file.core.windows.net"
    }
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags for Private DNS VNet links."
  default     = {}
}
