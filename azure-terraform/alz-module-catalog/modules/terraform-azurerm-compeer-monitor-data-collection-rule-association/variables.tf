variable "name" {
  type        = string
  description = "Association name."
  default     = null
}

variable "target_resource_id" {
  type        = string
  description = "Target Azure resource ID."
}

variable "data_collection_rule_id" {
  type        = string
  description = "Data Collection Rule ID."
  default     = null
}

variable "data_collection_endpoint_id" {
  type        = string
  description = "Data Collection Endpoint ID."
  default     = null
}

variable "description" {
  type        = string
  description = "Association description."
  default     = null
}
