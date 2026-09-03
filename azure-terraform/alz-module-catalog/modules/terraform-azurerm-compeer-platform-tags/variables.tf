# =============================================================================
# Enterprise tag schema (design-doc tag tables). Every tag is an OPTIONAL input
# with a null default - the module defines the whole vocabulary so a caller can
# set only the tags it has values for. The output map drops any tag left null.
#
# `missing_mandatory` reports which of the Required=Yes tags were not supplied,
# so a caller that wants to enforce them can `precondition` on it.
# =============================================================================

# ---- Mandatory (Required = Yes) --------------------------------------------
variable "environment" {
  type        = string
  description = "Mandatory. Deployment environment (e.g. prod, uat, test, dev, sandbox)."
  default     = null
}

variable "application" {
  type        = string
  description = "Mandatory. Application / service this resource belongs to."
  default     = null
}

variable "owner" {
  type        = string
  description = "Mandatory. Accountable owner (team or distribution list)."
  default     = null
}

variable "source_repo" {
  type        = string
  description = "Mandatory. Repository that provisions the resource."
  default     = null
}

variable "created_on" {
  type        = string
  description = "Mandatory. Creation date (ISO-8601, e.g. 2026-09-02)."
  default     = null
}

variable "criticality_tier" {
  type        = string
  description = "Mandatory. Business criticality tier."
  default     = null
}

variable "data_classification" {
  type        = string
  description = "Mandatory. Data classification: public | internal | confidential | restricted."
  default     = null

  validation {
    condition     = var.data_classification == null ? true : contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification must be public, internal, confidential, or restricted."
  }
}

variable "lifecycle_state" {
  type        = string
  description = "Mandatory. Lifecycle state (e.g. active, deprecated, decommissioning)."
  default     = null
}

variable "cost_center" {
  type        = string
  description = "Mandatory. Cost center / chargeback key."
  default     = null
}

variable "gl_category" {
  type        = string
  description = "Mandatory. General-ledger category for financial reporting."
  default     = null
}

# ---- Optional -------------------------------------------------------------
variable "application_component" {
  type        = string
  description = "Optional. Sub-component of the application."
  default     = null
}

variable "modified_on" {
  type        = string
  description = "Optional. Last-modified date (ISO-8601)."
  default     = null
}

# ---- Conditional --------------------------------------------------------
variable "created_by" {
  type        = string
  description = "Conditional. Identity/principal that created the resource."
  default     = null
}

variable "dr_tier" {
  type        = string
  description = "Conditional. Disaster-recovery tier."
  default     = null
}

# ---- Required only for sandbox / temporary / POC / exception resources ----
variable "expiration_date" {
  type        = string
  description = "Required for sandbox / temporary / POC / exception resources (ISO-8601). Optional otherwise."
  default     = null
}

# ---- Escape hatch --------------------------------------------------------
variable "additional_tags" {
  type        = map(string)
  description = "Extra tags merged last (these win on key collision)."
  default     = {}
}
