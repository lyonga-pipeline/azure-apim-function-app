variable "create_resource_group" {
  description = "Whether to create resource group and use it for all networking resources"
  default     = false
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
}

variable "vnetwork_name" {
  description = "Name of your Azure Virtual Network"
}

variable "vnet_address_space" {
  description = "The address space to be used for the Azure virtual network."
}

variable "create_ddos_plan" {
  description = "Create an ddos plan - Default is false"
  default     = false
}

variable "ddos_plan_name" {
  description = "The name of AzureNetwork DDoS Protection Plan"
  type        = string
  default     = null
}

variable "create_network_watcher" {
  description = "Controls if Network Watcher resources should be created for the Azure subscription"
  default     = false
}

variable "subnets" {
  description = "For each subnet, create an object that contain fields"
  default     = {}
}

variable "dns_servers" {
  description = "List of IP addresses of DNS servers"
  type        = list(string)
  default     = ["10.100.113.4", "10.100.113.5"]
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = null
}

// variable "diagnostic_setting_name" {
//   description = "Name for the diagnostic settings"
//   type        = string
// }

// variable "log_analytics_workspace_id" {
//   description = "Specifies the ID of a Log Analytics Workspace where Diagnostic Data should be sent."
//   type        = string
// }

// variable "log_analytics_destination_type" {
//   description = "When set to 'Dedicated' logs sent to a Log Analytics workspace will go into resource specific tables, instead of the legacy AzureDiagnostics table."
//   type        = string
//   default     = "AzureDiagnostics"
// }