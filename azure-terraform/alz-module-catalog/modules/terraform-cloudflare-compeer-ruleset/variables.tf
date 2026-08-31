variable "ruleset_kind" {
  description = "Type of Ruleset to create. Available values: custom, managed, root, zone."
  type        = string
}

variable "ruleset_name" {
  description = "Name of the ruleset."
  type        = string
}

variable "ruleset_phase" {
  description = "Point in the request/response lifecycle where the ruleset will be created."
  type        = string
}

variable "cloudflare_account_id" {
  description = "The account identifier to target for the resource."
  type        = string
  default     = null
}

variable "description" {
  description = "Brief summary of the ruleset and its intended use."
  type        = string
  default     = null
}

variable "zone_id" {
  description = "The zone identifier to target for the resource."
  type        = string
  default     = null
}

variable "rules" {
  description = "List of rules to apply to the ruleset."
  type = list(object({
    expression  = string
    action      = optional(string)
    description = optional(string)
    enabled     = optional(bool)
    ref         = optional(string)
    action_parameters = optional(object({
      automatic_https_rewrites   = optional(bool)
      bic                        = optional(bool)
      cache                      = optional(bool)
      content                    = optional(string)
      content_type               = optional(string)
      disable_apps               = optional(bool)
      disable_railgun            = optional(bool)
      disable_zaraz              = optional(bool)
      email_obfuscation          = optional(bool)
      host_header                = optional(string)
      hotlink_protection         = optional(bool)
      id                         = optional(string)
      increment                  = optional(number)
      mirage                     = optional(bool)
      opportunistic_encryption   = optional(bool)
      origin_cache_control       = optional(bool)
      origin_error_page_passthru = optional(bool)
      polish                     = optional(string)
      read_timeout               = optional(number)
      respect_strong_etags       = optional(bool)
      rocket_loader              = optional(bool)
      ruleset                    = optional(string)
      security_level             = optional(string)
      server_side_excludes       = optional(bool)
      ssl                        = optional(string)
      status_code                = optional(number)
      sxg                        = optional(bool)
      version                    = optional(string)

      algorithms = optional(object({
        name = string
      }))
      autominify = optional(object({
        css  = optional(bool)
        html = optional(bool)
        js   = optional(bool)
      }))
      browser_ttl = optional(object({
        mode    = string
        default = optional(number)
      }))
      cache_key = optional(object({
        cache_by_device_type       = optional(bool)
        cache_deception_armor      = optional(bool)
        ignore_query_strings_order = optional(bool)
        custom_key = optional(object({
          cookie = optional(object({
            check_presence = optional(list(string))
            include        = optional(list(string))
          }))
          header = optional(object({
            check_presence = optional(list(string))
            exclude_origin = optional(bool)
            include        = optional(list(string))
          }))
          host = optional(object({
            resolved = optional(bool)
          }))
          query_string = optional(object({
            check_presence = optional(list(string))
            exclude        = optional(list(string))
            include        = optional(list(string))
          }))
          user = optional(object({
            device_type = optional(bool)
            geo         = optional(bool)
            lang        = optional(bool)
          }))
        }))
      }))
      edge_ttl = optional(object({
        mode    = string
        default = optional(number)
        status_code_ttl = optional(object({
          status_code = optional(number)
          value       = optional(number)
          status_code_range = optional(object({
            from = optional(number)
            to   = optional(number)
          }))
        }))
      }))
      from_list = optional(object({
        key  = optional(string)
        name = optional(string)
      }))
      from_value = optional(object({
        preserve_query_string = optional(bool)
        status_code           = optional(number)
        target_url = optional(object({
          expression = optional(string)
          value      = optional(string)
        }))
      }))
      headers = optional(object({
        expression = optional(string)
        name       = optional(string)
        operation  = optional(string)
        value      = optional(string)
      }))
      matched_data = optional(object({
        public_key = optional(string)
      }))
      origin = optional(object({
        host = optional(string)
        port = optional(number)
      }))
      overrides = optional(object({
        action            = optional(string)
        enabled           = optional(bool)
        sensitivity_level = optional(string)
        categories = optional(object({
          action   = optional(string)
          category = optional(string)
          enabled  = optional(bool)
        }))
        rules = optional(object({
          action            = optional(string)
          enabled           = optional(bool)
          id                = optional(string)
          score_threshold   = optional(number)
          sensitivity_level = optional(string)
        }))
      }))
      response = optional(object({
        content      = optional(string)
        content_type = optional(string)
        status_code  = optional(number)
      }))
      serve_stale = optional(object({
        disable_stale_while_updating = optional(bool)
      }))
      sni = optional(object({
        value = optional(string)
      }))
      uri = optional(object({
        origin = optional(string)
        path = optional(object({
          expression = optional(string)
          value      = optional(string)
        }))
        query = optional(object({
          expression = optional(string)
          value      = optional(string)
        }))
      }))
    }))
    exposed_credential_check = optional(object({
      password_expression = optional(string)
      username_expression = optional(string)
    }))
    logging = optional(object({
      enabled = optional(bool)
    }))
    ratelimit = optional(object({
      requests_to_origin         = bool
      characteristics            = optional(list(string))
      counting_expression        = optional(string)
      mitigation_timeout         = optional(number)
      period                     = optional(number)
      requests_per_period        = optional(number)
      score_per_period           = optional(number)
      score_response_header_name = optional(string)
    }))
  }))
  default = []
}
