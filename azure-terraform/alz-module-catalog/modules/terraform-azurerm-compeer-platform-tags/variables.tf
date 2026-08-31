variable "environment" {
  type        = string
  description = "Environment tag value: np1, np2, np3, prod, or shared."

  validation {
    condition     = contains(["np1", "np2", "np3", "prod", "shared"], var.environment)
    error_message = "environment must be np1, np2, np3, prod, or shared."
  }
}

variable "application" {
  type        = string
  description = "Application or service code."
}

variable "created_by" {
  type        = string
  description = "Provisioning source."
  default     = "terraform"
}

variable "business_owner" {
  type        = string
  description = "Business or BT owner tag value."
  default     = null
}

variable "source_repo" {
  type        = string
  description = "Source repository tag value."
  default     = null
}

variable "terraform_workspace" {
  type        = string
  description = "Terraform workspace or stack tag."
  default     = null
}

variable "recovery_tier" {
  type        = string
  description = "Recovery posture such as rubrik, iaC, none."
  default     = null
}

variable "cost_center" {
  type        = string
  description = "Cost center or chargeback key."
  default     = null
}

variable "data_classification" {
  type        = string
  description = "Data classification tag: public, internal, confidential, or restricted."
  default     = "confidential"

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification must be public, internal, confidential, or restricted."
  }
}

variable "compliance_boundary" {
  type        = string
  description = "Compliance boundary or regulatory domain."
  default     = "finserv"
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tag values."
  default     = {}
}
