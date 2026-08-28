variable "account_id" {
  type        = string
  description = "Cloudflare account ID."
}

variable "name" {
  type        = string
  description = "Cloudflare Zero Trust tunnel name."
}

variable "tunnel_secret" {
  type        = string
  description = "Base64-encoded tunnel secret. Keep this in HCP sensitive variables or an approved secret store."
  sensitive   = true
}

variable "config_src" {
  type        = string
  description = "Tunnel configuration source."
  default     = "cloudflare"
}

variable "ingress_rules" {
  type = list(object({
    hostname = optional(string)
    path     = optional(string)
    service  = string
    origin_request = optional(object({
      bastion_mode             = optional(bool)
      ca_pool                  = optional(string)
      connect_timeout          = optional(string)
      disable_chunked_encoding = optional(bool)
      http2_origin             = optional(bool)
      http_host_header         = optional(string)
      keep_alive_connections   = optional(number)
      keep_alive_timeout       = optional(string)
      no_happy_eyeballs        = optional(bool)
      no_tls_verify            = optional(bool)
      origin_server_name       = optional(string)
      proxy_address            = optional(string)
      proxy_port               = optional(number)
      proxy_type               = optional(string)
      tcp_keep_alive           = optional(string)
      tls_timeout              = optional(string)
    }))
  }))
  default     = []
  description = "Remotely managed tunnel ingress rules. A terminal catch-all rule is appended automatically."
}

variable "catch_all_service" {
  type        = string
  description = "Terminal catch-all service for unmatched tunnel requests."
  default     = "http_status:404"
}

variable "dns_records" {
  type = map(object({
    zone_id         = string
    name            = string
    type            = optional(string, "CNAME")
    content         = optional(string)
    ttl             = optional(number, 1)
    proxied         = optional(bool, true)
    comment         = optional(string)
    priority        = optional(number)
    allow_overwrite = optional(bool, false)
    tags            = optional(list(string))
  }))
  default     = {}
  description = "Cloudflare DNS records that should point at the tunnel CNAME unless content is explicitly set."
}

variable "access_applications" {
  type = map(object({
    name                         = string
    domain                       = string
    type                         = optional(string, "self_hosted")
    zone_id                      = optional(string)
    allowed_idps                 = optional(list(string))
    auto_redirect_to_identity    = optional(bool)
    app_launcher_visible         = optional(bool)
    allow_authenticate_via_warp  = optional(bool)
    domain_type                  = optional(string)
    enable_binding_cookie        = optional(bool)
    http_only_cookie_attribute   = optional(bool)
    options_preflight_bypass     = optional(bool)
    same_site_cookie_attribute   = optional(string)
    self_hosted_domains          = optional(list(string))
    service_auth_401_redirect    = optional(bool)
    session_duration             = optional(string)
    skip_app_launcher_login_page = optional(bool)
    skip_interstitial            = optional(bool)
    custom_deny_message          = optional(string)
    custom_deny_url              = optional(string)
    custom_non_identity_deny_url = optional(string)
    custom_pages                 = optional(list(string))
    tags                         = optional(list(string))
  }))
  default     = {}
  description = "Optional Cloudflare Access applications published through the tunnel."
}

variable "access_policies" {
  type = map(object({
    name                           = string
    application_key                = optional(string)
    application_id                 = optional(string)
    zone_id                        = optional(string)
    decision                       = optional(string, "allow")
    precedence                     = number
    session_duration               = optional(string)
    approval_required              = optional(bool)
    isolation_required             = optional(bool)
    purpose_justification_prompt   = optional(string)
    purpose_justification_required = optional(bool)
    include = list(object({
      any_valid_service_token = optional(bool)
      auth_method             = optional(string)
      certificate             = optional(bool)
      common_name             = optional(string)
      common_names            = optional(list(string))
      device_posture          = optional(list(string))
      email                   = optional(list(string))
      email_domain            = optional(list(string))
      email_list              = optional(list(string))
      everyone                = optional(bool)
      geo                     = optional(list(string))
      group                   = optional(list(string))
      ip                      = optional(list(string))
      ip_list                 = optional(list(string))
      login_method            = optional(list(string))
      service_token           = optional(list(string))
    }))
    exclude = optional(list(object({
      any_valid_service_token = optional(bool)
      auth_method             = optional(string)
      certificate             = optional(bool)
      common_name             = optional(string)
      common_names            = optional(list(string))
      device_posture          = optional(list(string))
      email                   = optional(list(string))
      email_domain            = optional(list(string))
      email_list              = optional(list(string))
      everyone                = optional(bool)
      geo                     = optional(list(string))
      group                   = optional(list(string))
      ip                      = optional(list(string))
      ip_list                 = optional(list(string))
      login_method            = optional(list(string))
      service_token           = optional(list(string))
    })), [])
    require = optional(list(object({
      any_valid_service_token = optional(bool)
      auth_method             = optional(string)
      certificate             = optional(bool)
      common_name             = optional(string)
      common_names            = optional(list(string))
      device_posture          = optional(list(string))
      email                   = optional(list(string))
      email_domain            = optional(list(string))
      email_list              = optional(list(string))
      everyone                = optional(bool)
      geo                     = optional(list(string))
      group                   = optional(list(string))
      ip                      = optional(list(string))
      ip_list                 = optional(list(string))
      login_method            = optional(list(string))
      service_token           = optional(list(string))
    })), [])
  }))
  default     = {}
  description = "Optional Cloudflare Access policies. Include conditions are required by Cloudflare."

  validation {
    condition = alltrue([
      for policy in values(var.access_policies) : length(policy.include) > 0
    ])
    error_message = "Each access policy must include at least one include condition."
  }
}
