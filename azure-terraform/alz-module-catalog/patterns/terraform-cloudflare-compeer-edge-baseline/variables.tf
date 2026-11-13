variable "enabled" {
  description = "Master switch for the Cloudflare edge baseline."
  type        = bool
  default     = false
}

variable "zones" {
  description = "Cloudflare zones keyed by logical name."
  type = map(object({
    zone       = string
    account_id = string
    type       = optional(string, "full")
    paused     = optional(bool, false)
  }))
  default = {}
}

variable "records" {
  description = "Cloudflare DNS records keyed by logical name."
  type = map(object({
    zone_key        = optional(string)
    zone_id         = optional(string)
    name            = string
    value           = optional(string)
    content         = optional(string)
    type            = string
    ttl             = optional(number, 1)
    proxied         = optional(bool, true)
    comment         = optional(string)
    priority        = optional(number)
    allow_overwrite = optional(bool, false)
    tags            = optional(list(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for record in values(var.records) :
      (try(record.zone_key, null) != null || try(record.zone_id, null) != null) &&
      !(try(record.zone_key, null) != null && try(record.zone_id, null) != null)
    ])
    error_message = "Each record must set exactly one of zone_key or zone_id."
  }
}

variable "rulesets" {
  description = "Cloudflare rulesets keyed by logical name."
  type = map(object({
    zone_key    = optional(string)
    zone_id     = optional(string)
    account_id  = optional(string)
    kind        = string
    name        = string
    phase       = string
    description = optional(string)
    rules       = optional(list(any), [])
  }))
  default = {}
}

variable "tunnels" {
  description = "Cloudflare Zero Trust tunnels keyed by logical name."
  type = map(object({
    enabled             = optional(bool, true)
    account_id          = string
    name                = string
    tunnel_secret_key   = optional(string)
    config_src          = optional(string, "cloudflare")
    ingress_rules       = optional(list(any), [])
    catch_all_service   = optional(string, "http_status:404")
    dns_records         = optional(map(any), {})
    access_applications = optional(map(any), {})
    access_policies     = optional(map(any), {})
    access_team_name    = optional(string)
  }))
  default = {}
}

variable "tunnel_secrets" {
  description = "Sensitive tunnel secrets keyed by tunnel key or tunnels[*].tunnel_secret_key."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "enforce_enterprise_controls" {
  type        = bool
  default     = false
  description = "Enforce reviewed external-app inventory, HTTPS origins and Access coverage or an approved public-auth exception. Enable in the deployment root."
}

variable "approved_public_applications" {
  type = map(object({
    classification                 = string
    approval_reference             = string
    external_authentication_reason = optional(string)
  }))
  default     = {}
  description = "Approved exact public hostnames; classification must be external-apps. Non-Access apps require an explicit alternative-authentication justification."
}
