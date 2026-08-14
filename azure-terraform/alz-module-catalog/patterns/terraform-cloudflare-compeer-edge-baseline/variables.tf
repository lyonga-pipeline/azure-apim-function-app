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
    zone_key = string
    name     = string
    value    = string
    type     = string
    ttl      = optional(number, 1)
    proxied  = optional(bool, true)
    comment  = optional(string)
    priority = optional(number)
  }))
  default = {}
}

variable "rulesets" {
  description = "Cloudflare rulesets keyed by logical name."
  type = map(object({
    zone_key    = optional(string)
    account_id  = optional(string)
    kind        = string
    name        = string
    phase       = string
    description = optional(string)
    rules       = optional(list(any), [])
  }))
  default = {}
}
