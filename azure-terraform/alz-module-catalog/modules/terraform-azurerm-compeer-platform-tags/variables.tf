# =============================================================================
# Enterprise tag schema (design-doc tag tables). Every tag is an OPTIONAL input
# with a null default - the module defines the whole vocabulary so a caller can
# set only the tags it has values for. The output map drops any tag left null.
#
# `missing_mandatory` reports which of the Required=Yes tags were not supplied,
# so a caller that wants to enforce them can `precondition` on it. This module
# validates the SHAPE of any value it's given; it is deliberately not the
# enforcement layer for whether a mandatory tag was supplied at all - that's
# OPA / Azure Policy's job (see README).
#
# A real calendar-date check (`can(timecmp("${var.x}T00:00:00Z", ...))`) is
# used throughout instead of the old `^\d{4}-\d{2}-\d{2}$` regex: the regex
# only checked digit shape, so "2026-99-99" or "2026-02-30" passed it. Feeding
# the same synthesized RFC3339 string to itself through timecmp() forces
# Terraform to actually parse it as a calendar date - confirmed empirically
# against real impossible dates (month 99, Feb 30, Feb 29 on a non-leap year,
# Apr 31) and malformed widths ("2026-9-2") before relying on it here.
# =============================================================================

# ---- Mandatory (Required = Yes) --------------------------------------------
variable "environment" {
  type        = string
  description = "Mandatory. Deployment environment: dev, test, uat, prod, sandbox, or poc. Extend this list only via a deliberate module version bump if a new durable or temporary environment is approved - see checks.tf for why the exact boundary of this list also drives the expiration_date requirement."
  default     = null

  validation {
    condition     = var.environment == null ? true : contains(["dev", "test", "uat", "prod", "sandbox", "poc"], lower(trimspace(var.environment)))
    error_message = "environment must be one of: dev, test, uat, prod, sandbox, poc."
  }
}

variable "application" {
  type        = string
  description = "Mandatory. Application / service this resource belongs to. Non-empty normalized application or platform identifier."
  default     = null

  validation {
    condition     = var.application == null ? true : length(trimspace(var.application)) > 0
    error_message = "application must be non-empty when supplied."
  }
}

variable "owner" {
  type        = string
  description = "Mandatory. Accountable owner: a non-empty team name, or a distribution-list email address."
  default     = null

  validation {
    condition = var.owner == null ? true : (
      length(trimspace(var.owner)) > 0 &&
      (!strcontains(var.owner, "@") || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.owner)))
    )
    error_message = "owner must be a non-empty team name, or - if it contains \"@\" - a well-formed distribution-list email address."
  }
}

variable "source_repo" {
  type        = string
  description = "Mandatory. Repository or IaC path that provisions the resource, as a URI (e.g. ado://Compeer/landing-zone, https://github.com/org/repo)."
  default     = null

  validation {
    condition     = var.source_repo == null ? true : can(regex("^[a-zA-Z][a-zA-Z0-9+.-]*://\\S+$", trimspace(var.source_repo)))
    error_message = "source_repo must be a non-empty URI with a scheme, e.g. ado://Compeer/landing-zone or https://github.com/org/repo."
  }
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
    principle this schema exists to protect.

    This module stays a pure string-in-string-out variable: it validates
    whatever frozen value it's handed, regardless of where that value came
    from. The recommended source is a `time_static` resource declared in the
    CONSUMING ROOT (not in this module - the root owns the deployment
    lifecycle boundary), e.g.:

      resource "time_static" "deployment_created" {}
      module "tags" {
        created_on = formatdate("YYYY-MM-DD", time_static.deployment_created.rfc3339)
      }

    `time_static` computes its value once, on the resource's first apply,
    and stores it in state - every later plan reuses the same value instead
    of recomputing it, unlike timestamp(). A pipeline-generated, persisted
    date is an equally valid source; timestamp() directly is the one thing
    to avoid.
  EOT
  default     = null

  validation {
    condition     = var.created_on == null ? true : can(timecmp("${var.created_on}T00:00:00Z", "${var.created_on}T00:00:00Z"))
    error_message = "created_on must be a real calendar date in YYYY-MM-DD format (e.g. 2026-09-02, not 2026-99-99 or 2026-02-30)."
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
  description = <<-EOT
    Mandatory. Resource lifecycle status (FinOps tag standard, exact
    meanings and usage guidance):
      active                - Resource is approved, in use, and expected to
                               continue operating. Use for production, shared,
                               and long-lived non-production resources.
      temporary             - Resource is intentionally short-lived and must
                               have an expiration date. Use for sandboxes,
                               POCs, test labs, one-time analysis, and migration
                               staging.
      pilot                 - Resource supports a formal pilot or controlled
                               rollout. Use for early cloud workloads, limited
                               production trials, and PLANT-related pilots.
      decommission-pending  - Resource is no longer strategically needed but
                               has not yet been removed. Use for post-migration
                               cleanup, dual-run transition, app retirement,
                               and pending data/archive validation.
      retired               - Resource should no longer be running or incurring
                               meaningful cost. Use only for records, snapshots,
                               final archive, or audit evidence; ideally time-boxed.
      exempt                - Resource has an approved exception from normal
                               lifecycle automation. Use for security tooling,
                               shared platform services, DR dependencies,
                               legal/audit hold, or vendor constraints.
  EOT
  default     = null

  validation {
    condition     = var.lifecycle_state == null ? true : contains(["active", "temporary", "pilot", "decommission-pending", "retired", "exempt"], var.lifecycle_state)
    error_message = "lifecycle_state must be one of: active, temporary, pilot, decommission-pending, retired, exempt."
  }
}

variable "cost_center" {
  type        = string
  description = "Mandatory. Cost center / chargeback key. Non-empty when supplied - a stricter Finance-approved format is deliberately not enforced yet; confirm the exact format with Finance before adding one."
  default     = null

  validation {
    condition     = var.cost_center == null ? true : length(trimspace(var.cost_center)) > 0
    error_message = "cost_center must be non-empty when supplied."
  }
}

variable "gl_category" {
  type        = string
  description = "Mandatory. General-ledger category for financial reporting. Non-empty when supplied - a stricter Finance-approved format is deliberately not enforced yet; confirm the exact format with Finance before adding one."
  default     = null

  validation {
    condition     = var.gl_category == null ? true : length(trimspace(var.gl_category)) > 0
    error_message = "gl_category must be non-empty when supplied."
  }
}

variable "appcode" {
  type        = string
  description = "Mandatory. Application code - the same short identifier the naming module's own `appcode` input uses, so a resource's tag matches its actual name prefix rather than drifting from it. At most 9 letters."
  default     = null

  validation {
    condition     = var.appcode == null ? true : can(regex("^[a-zA-Z]{1,9}$", trimspace(var.appcode)))
    error_message = "appcode must be 1-9 letters only (no digits, hyphens, or underscores) - the same constraint the naming module enforces on its own appcode input, since this tag exists to mirror it."
  }
}

# ---- Optional -------------------------------------------------------------
variable "application_component" {
  type        = string
  description = "Optional. Sub-component of the application. Non-empty when supplied."
  default     = null

  validation {
    condition     = var.application_component == null ? true : length(trimspace(var.application_component)) > 0
    error_message = "application_component must be non-empty when supplied."
  }
}

variable "modified_on" {
  type        = string
  description = "Optional. Last-modified date (ISO-8601). Must not be before created_on when both are set (see checks.tf)."
  default     = null

  validation {
    condition     = var.modified_on == null ? true : can(timecmp("${var.modified_on}T00:00:00Z", "${var.modified_on}T00:00:00Z"))
    error_message = "modified_on must be a real calendar date in YYYY-MM-DD format."
  }
}

# ---- Conditional --------------------------------------------------------
variable "created_by" {
  type        = string
  description = "Conditional. Deployment mechanism that created the resource. Fixed to \"Terraform\" - that IS the deployment mechanism for every resource this module tags, so the value is enforced, not just defaulted. `nullable = false` means an explicit null from a consuming pattern (e.g. an unset optional object field flowing through as null) still resolves to the default instead of bypassing it. If a future non-Terraform deployment mechanism must be supported, remove the validation block below but keep `nullable = false`."
  default     = "Terraform"
  nullable    = false

  validation {
    condition     = var.created_by == "Terraform"
    error_message = "created_by must be Terraform - every resource this module tags is deployed by Terraform, so this is fixed rather than caller-supplied. Remove this validation (keeping nullable = false) if a non-Terraform deployment mechanism must be recorded here in the future."
  }
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

variable "time_bound_exception" {
  type        = bool
  description = "Whether this specific approved lifecycle_state = \"exempt\" resource must carry an expiration_date. Exemptions are not automatically time-bound (a permanent exemption is valid and does not need one) - set this to true only when THIS exception was approved with a planned end date. Ignored for every lifecycle_state other than \"exempt\"; see checks.tf's expiration_date_required check."
  default     = false
}

# ---- Required only for sandbox / POC / temporary / time-bound-exception ----
# resources, or any environment outside the four standard durable ones -----
variable "expiration_date" {
  type        = string
  description = "Required when environment is sandbox or poc, lifecycle_state is temporary, or time_bound_exception is true (ISO-8601) - see checks.tf's expiration_date_required check. Optional otherwise. Must not be before created_on when both are set."
  default     = null

  validation {
    condition     = var.expiration_date == null ? true : can(timecmp("${var.expiration_date}T00:00:00Z", "${var.expiration_date}T00:00:00Z"))
    error_message = "expiration_date must be a real calendar date in YYYY-MM-DD format."
  }
}

# ---- Escape hatch --------------------------------------------------------
variable "additional_tags" {
  type        = map(string)
  description = "Extra tags for client- or workload-specific metadata ONLY - organization-specific keys that are not part of the standard schema below. Must not contain any standard tag key (environment, application, appcode, owner, source_repo, created_on, criticality_tier, data_classification, lifecycle_state, cost_center, gl_category, application_component, modified_on, created_by, dr_tier, expiration_date) - checks.tf rejects the plan outright if it does, so a caller cannot bypass a first-class input's own validation by routing the same key through here instead. Use the dedicated variable for every standard tag, even to leave it unset."
  default     = {}
}
