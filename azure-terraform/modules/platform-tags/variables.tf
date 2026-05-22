variable "environment" {
  type        = string
  description = "Environment tag value such as np1, np2, np3, prod, shared."
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
  description = "Data classification tag."
  default     = "confidential"
}

variable "compliance_boundary" {
  type        = string
  description = "Compliance boundary or regulatory domain."
  default     = "finserv"
}

variable "creation_date_utc" {
  type        = string
  description = "Optional immutable creation timestamp. Prefer setting once and then ignoring drift."
  default     = null
}

variable "last_modified_utc" {
  type        = string
  description = "Optional external last modified timestamp. Prefer managing outside Terraform."
  default     = null
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tag values."
  default     = {}
}
