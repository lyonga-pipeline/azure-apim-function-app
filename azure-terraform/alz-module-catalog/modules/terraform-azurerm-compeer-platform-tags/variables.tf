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
  description = <<-EOT
    Mandatory. Creation date (ISO-8601, e.g. 2026-09-02) - the date the
    resource was FIRST deployed, not the date of the current plan/apply.

    Deliberately NOT auto-computed with Terraform's timestamp() function:
    timestamp() re-evaluates on every single plan, which would make this
    tag (and therefore every resource's tag map) show a diff on every run
    forever - exactly the "durable, does not require redeployment" tagging
    principle this schema exists to protect. The design doc's own
    "Auto-populated by CI/CD pipeline" note means the PIPELINE captures
    "first deployed" once (e.g. only setting -var created_on=... on a
    resource's actual first apply, or reading it back from existing state/
    tags on every subsequent one) and passes a frozen literal value in from
    there - Terraform itself has no built-in way to know "is this truly the
    first apply" without state inspection the pipeline has to do anyway.
  EOT
  default     = null

  validation {
    condition     = var.created_on == null ? true : can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.created_on))
    error_message = "created_on must use YYYY-MM-DD format."
  }
}

variable "criticality_tier" {
  type        = string
  description = "Mandatory. Business and operational criticality of the workload: tier-0 (foundational enterprise/platform service - identity, networking, security tooling, core landing zone services, shared observability, key management), tier-1 (mission-critical business workload), tier-2 (important business/operational workload, manageable outage impact), tier-3 (low-criticality, non-production, experimental, temporary, or disposable), or tier-4."
  default     = null

  validation {
    condition     = var.criticality_tier == null ? true : contains(["tier-0", "tier-1", "tier-2", "tier-3", "tier-4"], var.criticality_tier)
    error_message = "criticality_tier must be one of: tier-0, tier-1, tier-2, tier-3, tier-4."
  }
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
  description = "Mandatory. Resource lifecycle status: active (approved, in use, expected to continue), temporary (intentionally short-lived, must have an expiration_date), pilot (formal pilot / controlled rollout), decommission-pending (no longer strategically needed, not yet removed), retired (should no longer be running or incurring meaningful cost), or exempt (approved exception from normal lifecycle automation)."
  default     = null

  validation {
    condition     = var.lifecycle_state == null ? true : contains(["active", "temporary", "pilot", "decommission-pending", "retired", "exempt"], var.lifecycle_state)
    error_message = "lifecycle_state must be one of: active, temporary, pilot, decommission-pending, retired, exempt."
  }
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

variable "appcode" {
  type        = string
  description = "Mandatory. Application code - the same short identifier the naming module's own `appcode` input uses, so a resource's tag matches its actual name prefix rather than drifting from it. At most 9 letters."
  default     = null

  validation {
    condition     = var.appcode == null ? true : can(regex("^[a-zA-Z]{1,9}$", var.appcode))
    error_message = "appcode must be 1-9 letters only (no digits, hyphens, or underscores) - the same constraint the naming module enforces on its own appcode input, since this tag exists to mirror it."
  }
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

  validation {
    condition     = var.modified_on == null ? true : can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.modified_on))
    error_message = "modified_on must use YYYY-MM-DD format."
  }
}

# ---- Conditional --------------------------------------------------------
variable "created_by" {
  type        = string
  description = "Conditional. Identity/principal that created the resource. Defaults to \"Terraform\" - that IS the deployment mechanism for every resource this module tags, so it's a genuinely accurate default rather than a placeholder. Override with a real pipeline/service-principal identity only if a caller has a more specific one and wants it recorded instead."
  default     = "Terraform"
}

variable "dr_tier" {
  type        = string
  description = "Conditional. Disaster-recovery tier: gold (multi-zone/multi-region, tested failover, strict RTO/RPO), silver (zone-redundant or region-recoverable, scheduled backups), bronze (backup/restore-based recovery, relaxed RTO/RPO), or none (no formal DR requirement - rebuild from IaC or discard)."
  default     = null

  validation {
    condition     = var.dr_tier == null ? true : contains(["gold", "silver", "bronze", "none"], var.dr_tier)
    error_message = "dr_tier must be one of: gold, silver, bronze, none."
  }
}

# ---- Required only for sandbox / temporary / POC / exception resources ----
variable "expiration_date" {
  type        = string
  description = "Required for sandbox / temporary / POC / exception resources (ISO-8601). Optional otherwise."
  default     = null

  validation {
    condition     = var.expiration_date == null ? true : can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.expiration_date))
    error_message = "expiration_date must use YYYY-MM-DD format."
  }
}

# ---- Escape hatch --------------------------------------------------------
variable "additional_tags" {
  type        = map(string)
  description = "Extra tags for client- or workload-specific metadata. First-class standard tag inputs win on key collision."
  default     = {}
}
