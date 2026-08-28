variable "cloudflare_api_token" {
  description = "Optional Cloudflare API token. Prefer CLOUDFLARE_API_TOKEN in HCP workspace variables."
  type        = string
  default     = null
  sensitive   = true
}

variable "zones" {
  description = "Cloudflare zones. Use an empty map when zones are managed outside this root."
  type        = map(any)
  default     = {}
}

variable "records" {
  description = "Cloudflare DNS records for ingress and App Gateway failover."
  type = map(object({
    zone_key        = optional(string)
    zone_id         = optional(string)
    name            = string
    type            = string
    value           = optional(string)
    data            = optional(map(any), {})
    ttl             = optional(number)
    proxied         = optional(bool)
    priority        = optional(number)
    allow_overwrite = optional(bool)
    comment         = optional(string)
    tags            = optional(set(string), [])
    timeouts        = optional(map(any), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for record in values(var.records) :
      (try(record.zone_key, null) != null) != (try(record.zone_id, null) != null)
    ])
    error_message = "Each record must set exactly one of zone_key or zone_id."
  }
}

variable "rulesets" {
  description = "Cloudflare rulesets for WAF/cache/transform controls."
  type = map(object({
    zone_key              = optional(string)
    zone_id               = optional(string)
    cloudflare_account_id = optional(string)
    ruleset_kind          = string
    ruleset_name          = string
    ruleset_phase         = string
    description           = optional(string)
    rules                 = optional(any, [])
  }))
  default = {}
}

variable "operational_contracts" {
  description = "Cloudflare controls not currently covered by approved Compeer modules."
  type = map(object({
    phase                = optional(string, "Phase 2")
    owner                = optional(string)
    enabled              = optional(bool, false)
    cost_disabled        = optional(bool, true)
    implementation_state = optional(string, "contract-only")
    required_controls    = optional(list(string), [])
    evidence_locations   = optional(list(string), [])
    notes                = optional(string)
  }))
  default = {}
}
