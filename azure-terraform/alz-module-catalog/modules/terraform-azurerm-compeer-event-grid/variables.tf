variable "eventgrid_topic_name" {
  type        = string
  description = "Specifies the name of the EventGrid Topic resource."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the existing resource group."
}

variable "location" {
  type        = string
  description = "Location where the resource needs to be placed."
  default     = "northcentralus"
}

variable "eventgrid_input_schema" {
  type        = string
  description = "Specifies the schema in which incoming events will be published to this domain. Allowed values are `CloudEventSchemaV1_0`, `CustomEventSchema`, or `EventGridSchema`"
  default     = "EventGridSchema"
}

variable "eventgrid_identity_type" {
  type        = string
  description = "Specifies the type of Managed Service Identity that should be configured on this Event Grid Topic."
  default     = "SystemAssigned"
}

variable "eventgrid_identity_ids" {
  type        = list(string)
  description = "Specifies a list of User Assigned Managed Identity IDs to be assigned to this Event Grid Topic."
  default     = []
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether or not public network access is allowed for this server."
  default     = false
}

variable "local_auth_enabled" {
  type        = bool
  description = "Whether local authentication methods is enabled for the EventGrid Topic."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "DEPRECATED: retained for backward compatibility; no longer used by the implementation. A mapping of tags to assign to the resource."
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
