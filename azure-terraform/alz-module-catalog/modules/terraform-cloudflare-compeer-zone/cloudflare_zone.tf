resource "cloudflare_zone" "zone" {
  account_id = var.account_id
  zone       = var.zone

  jump_start = var.zone_jump_start
  paused     = var.zone_paused
  plan       = var.zone_plan
  type       = var.zone_type
}

/*
You should not use this resource to manage every zone setting.
This resource is only intended to override those which you do not want the default.
Attempting to manage all settings will result in problems with the resource applying in a consistent manner.
*/
resource "cloudflare_zone_settings_override" "zone_settings" {
  count   = var.enable_zone_settings ? 1 : 0
  zone_id = cloudflare_zone.zone.id

  dynamic "settings" {
    for_each = var.settings
    content {
      always_online               = lookup(settings.value, "always_online", null)
      always_use_https            = lookup(settings.value, "always_use_https", null)
      automatic_https_rewrites    = lookup(settings.value, "automatic_https_rewrites", null)
      binary_ast                  = lookup(settings.value, "binary_ast", null)
      brotli                      = lookup(settings.value, "brotli", null)
      browser_cache_ttl           = lookup(settings.value, "browser_cache_ttl", null)
      browser_check               = lookup(settings.value, "browser_check", null)
      cache_level                 = lookup(settings.value, "cache_level", null)
      challenge_ttl               = lookup(settings.value, "challenge_ttl", null)
      ciphers                     = lookup(settings.value, "ciphers", null)
      cname_flattening            = lookup(settings.value, "cname_flattening", null)
      development_mode            = lookup(settings.value, "development_mode", null)
      early_hints                 = lookup(settings.value, "early_hints", null)
      email_obfuscation           = lookup(settings.value, "email_obfuscation", null)
      filter_logs_to_cloudflare   = lookup(settings.value, "filter_logs_to_cloudflare", null)
      h2_prioritization           = lookup(settings.value, "h2_prioritization", null)
      hotlink_protection          = lookup(settings.value, "hotlink_protection", null)
      http2                       = lookup(settings.value, "http2", null)
      http3                       = lookup(settings.value, "http3", null)
      image_resizing              = lookup(settings.value, "image_resizing", null)
      ip_geolocation              = lookup(settings.value, "ip_geolocation", null)
      ipv6                        = lookup(settings.value, "ipv6", null)
      log_to_cloudflare           = lookup(settings.value, "log_to_cloudflare", null)
      max_upload                  = lookup(settings.value, "max_upload", null)
      min_tls_version             = lookup(settings.value, "min_tls_version", null)
      mirage                      = lookup(settings.value, "mirage", null)
      opportunistic_encryption    = lookup(settings.value, "opportunistic_encryption", null)
      opportunistic_onion         = lookup(settings.value, "opportunistic_onion", null)
      orange_to_orange            = lookup(settings.value, "orange_to_orange", null)
      origin_error_page_pass_thru = lookup(settings.value, "origin_error_page_pass_thru", null)
      origin_max_http_version     = lookup(settings.value, "origin_max_http_version", null)
      polish                      = lookup(settings.value, "polish", null)
      prefetch_preload            = lookup(settings.value, "prefetch_preload", null)
      privacy_pass                = lookup(settings.value, "privacy_pass", null)
      proxy_read_timeout          = lookup(settings.value, "proxy_read_timeout", null)
      pseudo_ipv4                 = lookup(settings.value, "pseudo_ipv4", null)
      response_buffering          = lookup(settings.value, "response_buffering", null)
      rocket_loader               = lookup(settings.value, "rocket_loader", null)
      security_level              = lookup(settings.value, "security_level", null)
      server_side_exclude         = lookup(settings.value, "server_side_exclude", null)
      sort_query_string_for_cache = lookup(settings.value, "sort_query_string_for_cache", null)
      ssl                         = lookup(settings.value, "ssl", null)
      tls_1_3                     = lookup(settings.value, "tls_1_3", null)
      tls_client_auth             = lookup(settings.value, "tls_client_auth", null)
      true_client_ip_header       = lookup(settings.value, "true_client_ip_header", null)
      universal_ssl               = lookup(settings.value, "universal_ssl", null)
      visitor_ip                  = lookup(settings.value, "visitor_ip", null)
      waf                         = lookup(settings.value, "waf", null)
      webp                        = lookup(settings.value, "webp", null)
      websockets                  = lookup(settings.value, "websockets", null)
      zero_rtt                    = lookup(settings.value, "zero_rtt", null)

      dynamic "minify" {
        for_each = settings.value.minify != null ? [settings.value.minify] : []

        content {
          css  = minify.value.css
          html = minify.value.html
          js   = minify.value.js
        }
      }

      dynamic "mobile_redirect" {
        for_each = settings.value.mobile_redirect != null ? [settings.value.mobile_redirect] : []
        content {
          mobile_subdomain = mobile_redirect.value.mobile_subdomain
          status           = mobile_redirect.value.status
          strip_uri        = mobile_redirect.value.strip_uri
        }
      }

      dynamic "security_header" {
        for_each = settings.value.security_header != null ? [settings.value.security_header] : []
        content {
          enabled            = lookup(security_header.value, "enabled", null)
          include_subdomains = lookup(security_header.value, "include_subdomains", null)
          max_age            = lookup(security_header.value, "max_age", null)
          nosniff            = lookup(security_header.value, "nosniff", null)
          preload            = lookup(security_header.value, "preload", null)
        }
      }
    }
  }
}