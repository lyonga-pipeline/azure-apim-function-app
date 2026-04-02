variable "environment" {
  type        = string
  description = "Environment tag."
}

variable "subscription_id" {
  type        = string
  description = "Connectivity subscription id."
}

variable "subscription_catalog_entry_key" {
  type        = string
  description = "Entry key in the subscriptions catalog for this stack."
  default     = "connectivity"
}

variable "use_subscriptions_state" {
  type        = bool
  description = "Validate the stack subscription against the central subscriptions state."
  default     = true
}

variable "subscriptions_state_rg" {
  type        = string
  description = "Resource group hosting the subscriptions stack state."
  default     = "rg-tfstate-dev"
}

variable "subscriptions_state_sa" {
  type        = string
  description = "Storage account hosting the subscriptions stack state."
  default     = "demotest822e"
}

variable "subscriptions_state_container" {
  type        = string
  description = "Container hosting the subscriptions stack state."
  default     = "deploy-container"
}

variable "subscriptions_state_key" {
  type        = string
  description = "State blob key for the subscriptions stack."
  default     = "global/subscriptions.tfstate"
}

variable "subscriptions_state_subscription_id" {
  type        = string
  description = "Subscription containing the subscriptions stack remote state."
  default     = null
}

variable "application" {
  type        = string
  description = "Application code."
  default     = "connectivity"
}

variable "created_by" {
  type        = string
  description = "Provisioning source tag."
  default     = "terraform"
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Connectivity resource group name."
}

variable "hub_vnet_name" {
  type        = string
  description = "Hub VNet name."
}

variable "hub_address_space" {
  type        = list(string)
  description = "Hub VNet CIDR ranges."
}

variable "enable_firewall" {
  type        = bool
  description = "Deploy Azure Firewall into the hub."
  default     = false
}

variable "firewall_sku_tier" {
  type        = string
  description = "Azure Firewall SKU tier."
  default     = "Standard"
}

variable "firewall_network_rule_collections" {
  type = list(object({
    name     = string
    priority = number
    action   = string
    rules = list(object({
      name                  = string
      source_addresses      = list(string)
      destination_ports     = list(string)
      destination_addresses = optional(list(string))
      destination_fqdns     = optional(list(string))
      protocols             = list(string)
    }))
  }))
  description = "Optional Azure Firewall network rule collections to attach when the hub firewall is enabled."
  default     = []
}

variable "firewall_policy_name" {
  type        = string
  description = "Optional Azure Firewall Policy name override."
  default     = null
}

variable "firewall_policy_rule_collection_group_name" {
  type        = string
  description = "Azure Firewall Policy rule collection group name."
  default     = "default-network"
}

variable "firewall_policy_rule_collection_group_priority" {
  type        = number
  description = "Azure Firewall Policy rule collection group priority."
  default     = 100
}

variable "firewall_threat_intelligence_mode" {
  type        = string
  description = "Azure Firewall Policy threat intelligence mode."
  default     = "Alert"
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Deploy a NAT Gateway in the hub and attach it to selected hub subnets."
  default     = false
}

variable "nat_gateway_name" {
  type        = string
  description = "Optional NAT Gateway name override."
  default     = null
}

variable "nat_gateway_subnet_keys" {
  type        = list(string)
  description = "Hub subnet keys to associate with the NAT Gateway."
  default     = ["AzureFirewallSubnet"]
}

variable "nat_gateway_create_public_ip" {
  type        = bool
  description = "Create and associate a Standard public IP for the NAT Gateway."
  default     = true
}

variable "nat_gateway_idle_timeout_in_minutes" {
  type        = number
  description = "NAT Gateway idle timeout in minutes."
  default     = 10
}

variable "nat_gateway_zones" {
  type        = list(string)
  description = "Availability zones for the NAT Gateway and its public IP."
  default     = []
}

variable "enable_bastion" {
  type        = bool
  description = "Deploy Azure Bastion into the hub."
  default     = false
}

variable "bastion_name" {
  type        = string
  description = "Optional Azure Bastion name override."
  default     = null
}

variable "bastion_sku" {
  type        = string
  description = "Azure Bastion SKU."
  default     = "Standard"
}

variable "bastion_copy_paste_enabled" {
  type        = bool
  description = "Enable copy/paste in Bastion sessions."
  default     = true
}

variable "bastion_file_copy_enabled" {
  type        = bool
  description = "Enable file copy in Bastion sessions."
  default     = false
}

variable "bastion_ip_connect_enabled" {
  type        = bool
  description = "Enable IP-based Bastion connections."
  default     = false
}

variable "bastion_shareable_link_enabled" {
  type        = bool
  description = "Enable shareable links in Bastion."
  default     = false
}

variable "bastion_tunneling_enabled" {
  type        = bool
  description = "Enable native client tunneling in Bastion."
  default     = true
}

variable "bastion_scale_units" {
  type        = number
  description = "Azure Bastion scale units."
  default     = 2
}

variable "dns_servers" {
  type        = list(string)
  description = "Optional custom DNS servers."
  default     = null
}

variable "private_dns_zones" {
  type = map(object({
    name = string
  }))
  description = "Private DNS zones to create in the hub."
  default = {
    keyvault   = { name = "privatelink.vaultcore.azure.net" }
    blob       = { name = "privatelink.blob.core.windows.net" }
    queue      = { name = "privatelink.queue.core.windows.net" }
    table      = { name = "privatelink.table.core.windows.net" }
    file       = { name = "privatelink.file.core.windows.net" }
    websites   = { name = "privatelink.azurewebsites.net" }
    sql        = { name = "privatelink.database.windows.net" }
    servicebus = { name = "privatelink.servicebus.windows.net" }
    appconfig  = { name = "privatelink.azconfig.io" }
  }
}

variable "business_owner" {
  type        = string
  description = "Business owner tag."
  default     = "network"
}

variable "source_repo" {
  type        = string
  description = "Source repository tag."
  default     = "azure-apim-function-app"
}

variable "terraform_workspace" {
  type        = string
  description = "Terraform workspace or stack name."
  default     = "platform-connectivity"
}

variable "recovery_tier" {
  type        = string
  description = "Recovery method tag."
  default     = "terraform"
}

variable "cost_center" {
  type        = string
  description = "Cost center tag."
  default     = "shared-network"
}

variable "compliance_boundary" {
  type        = string
  description = "Compliance boundary tag."
  default     = "finserv"
}

variable "creation_date_utc" {
  type        = string
  description = "Optional immutable creation timestamp tag."
  default     = null
}

variable "last_modified_utc" {
  type        = string
  description = "Optional last modified timestamp tag."
  default     = null
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags."
  default     = {}
}
