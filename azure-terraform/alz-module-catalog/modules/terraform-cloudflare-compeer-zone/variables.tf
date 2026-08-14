variable "enable_zone_settings" {
  description = "Whether to enable zone settings"
  type        = bool
  default     = false
}

variable "account_id" {
  description = "Account ID to manage the zone resource in."
  type        = string
}

variable "zone" {
  description = "The DNS zone name which will be added. Modifying this attribute will force creation of a new resource."
  type        = string
}

variable "zone_jump_start" {
  description = "Whether to scan for DNS records on creation. Ignored after zone is created."
  type        = bool
  default     = false
}

variable "zone_paused" {
  description = "Whether this zone is paused (traffic bypasses Cloudflare)."
  type        = bool
  default     = false
}

variable "zone_plan" {
  description = "The name of the commercial plan to apply to the zone."
  type        = string
  validation {
    condition     = can(index(["free", "lite", "pro", "pro_plus", "business", "enterprise", "partners_free", "partners_pro", "partners_business", "partners_enterprise"], var.zone_plan))
    error_message = "The zone plan is not valid."
  }
  default = null
}

variable "zone_type" {
  description = "A full zone implies that DNS is hosted with Cloudflare. A partial zone is typically a partner-hosted zone or a CNAME setup."
  type        = string
  default     = "full"
  validation {
    condition     = can(index(["full", "partial"], var.zone_type))
    error_message = "The zone type is not valid."
  }
}

variable "settings" {
  description = "The Cloudflare Zone settings."
  type = list(object({
    always_online               = optional(string)
    always_use_https            = optional(string)
    automatic_https_rewrites    = optional(string)
    binary_ast                  = optional(string)
    brotli                      = optional(string)
    browser_cache_ttl           = optional(number)
    browser_check               = optional(string)
    cache_level                 = optional(string)
    challenge_ttl               = optional(number)
    ciphers                     = optional(string)
    cname_flattening            = optional(string)
    development_mode            = optional(string)
    early_hints                 = optional(string)
    email_obfuscation           = optional(string)
    filter_logs_to_cloudflare   = optional(string)
    h2_prioritization           = optional(string)
    hotlink_protection          = optional(string)
    http2                       = optional(string)
    http3                       = optional(string)
    image_resizing              = optional(string)
    ip_geolocation              = optional(string)
    ipv6                        = optional(string)
    log_to_cloudflare           = optional(string)
    max_upload                  = optional(string)
    min_tls_version             = optional(string)
    mirage                      = optional(string)
    opportunistic_encryption    = optional(string)
    opportunistic_onion         = optional(string)
    orange_to_orange            = optional(string)
    origin_error_page_pass_thru = optional(string)
    origin_max_http_version     = optional(string)
    polish                      = optional(string)
    prefetch_preload            = optional(string)
    privacy_pass                = optional(string)
    proxy_read_timeout          = optional(string)
    pseudo_ipv4                 = optional(string)
    response_buffering          = optional(string)
    rocket_loader               = optional(string)
    security_level              = optional(string)
    server_side_exclude         = optional(string)
    sort_query_string_for_cache = optional(string)
    ssl                         = optional(string)
    tls_1_3                     = optional(string)
    tls_client_auth             = optional(string)
    true_client_ip_header       = optional(string)
    universal_ssl               = optional(string)
    visitor_ip                  = optional(string)
    waf                         = optional(string)
    webp                        = optional(string)
    websockets                  = optional(string)
    zero_rtt                    = optional(string)

    minify = optional(object({
      css  = string
      html = string
      js   = string
    }))

    mobile_redirect = optional(object({
      mobile_subdomain = string
      status           = string
      strip_uri        = bool
    }))

    security_header = optional(object({
      enabled            = optional(bool)
      include_subdomains = optional(bool)
      max_age            = optional(number)
      nosniff            = optional(bool)
      preload            = optional(bool)
    }))
  }))

  default = []
}
