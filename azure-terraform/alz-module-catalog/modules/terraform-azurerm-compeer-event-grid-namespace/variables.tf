variable "namespace_name" {
  description = "Specifies the name of the Event Grid Namespace."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the existing resource group."
  type        = string
}

variable "location" {
  description = "Location where the resource needs to be placed."
  type        = string
  default     = "northcentralus"
}

variable "capacity" {
  description = "Specifies the capacity for the Event Grid Namespace."
  type        = number
  default     = 1
}

variable "public_network_access" {
  description = "Whether public network access is allowed. Defaults to Disabled."
  type        = string
  default     = "Disabled"
}

variable "sku" {
  description = "Defines the tier to use. The only possible value is Standard."
  type        = string
  default     = "Standard"
}

variable "identity_type" {
  description = "Type of Managed Service Identity for the namespace."
  type        = string
  default     = "SystemAssigned"
}

variable "identity_ids" {
  description = "List of User Assigned Managed Identity IDs if identity_type includes `UserAssigned`."
  type        = list(string)
  default     = []
}

variable "inbound_ip_rules" {
  description = "List of IP rules for inbound access. Each entry requires `ip_mask` and `action`."
  type = list(object({
    ip_mask = string
    action  = optional(string, "Allow")
  }))
  default = []
}

variable "topic_spaces_configuration" {
  description = "Configuration for topic spaces including optional routing enrichments. Set to null (default) to disable MQTT/topic spaces."
  type = object({
    alternative_authentication_name_source          = optional(list(string), [])
    maximum_client_sessions_per_authentication_name = optional(number, 10)
    maximum_session_expiry_in_hours                 = optional(number, 8)
    route_topic_id                                  = optional(string, null)
  })
  default = null
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "eventgrid_subscription" {
  type = list(object({
    name                                 = string
    scope                                = optional(string)
    event_delivery_schema                = optional(string)
    azure_function_endpoint              = optional(map(string))
    storage_queue_endpoint               = optional(map(string))
    storage_blob_dead_letter_destination = optional(map(string))
    delivery_property                    = optional(map(string))
    dead_letter_identity                 = optional(map(string))
    delivery_identity                    = optional(map(string))
    eventhub_endpoint_id                 = optional(string)
    hybrid_connection_endpoint_id        = optional(string)
    service_bus_queue_endpoint_id        = optional(string)
    service_bus_topic_endpoint_id        = optional(string)
    webhook_endpoint                     = optional(map(string))
  }))
  description = "List of subscriptions to be subscribed to the ."
  default     = []
}
