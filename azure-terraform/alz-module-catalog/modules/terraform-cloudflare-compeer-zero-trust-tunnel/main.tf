resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id = var.account_id
  name       = var.name
  secret     = var.tunnel_secret
  config_src = var.config_src
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id

  config {
    dynamic "ingress_rule" {
      for_each = concat(var.ingress_rules, [{ service = var.catch_all_service }])
      content {
        hostname = try(ingress_rule.value.hostname, null)
        path     = try(ingress_rule.value.path, null)
        service  = ingress_rule.value.service

        dynamic "origin_request" {
          for_each = try(ingress_rule.value.origin_request, null) == null ? [] : [ingress_rule.value.origin_request]
          content {
            bastion_mode             = try(origin_request.value.bastion_mode, null)
            ca_pool                  = try(origin_request.value.ca_pool, null)
            connect_timeout          = try(origin_request.value.connect_timeout, null)
            disable_chunked_encoding = try(origin_request.value.disable_chunked_encoding, null)
            http2_origin             = try(origin_request.value.http2_origin, null)
            http_host_header         = try(origin_request.value.http_host_header, null)
            keep_alive_connections   = try(origin_request.value.keep_alive_connections, null)
            keep_alive_timeout       = try(origin_request.value.keep_alive_timeout, null)
            no_happy_eyeballs        = try(origin_request.value.no_happy_eyeballs, null)
            no_tls_verify            = try(origin_request.value.no_tls_verify, null)
            origin_server_name       = try(origin_request.value.origin_server_name, null)
            proxy_address            = try(origin_request.value.proxy_address, null)
            proxy_port               = try(origin_request.value.proxy_port, null)
            proxy_type               = try(origin_request.value.proxy_type, null)
            tcp_keep_alive           = try(origin_request.value.tcp_keep_alive, null)
            tls_timeout              = try(origin_request.value.tls_timeout, null)
          }
        }
      }
    }
  }
}

resource "cloudflare_record" "this" {
  for_each = var.dns_records

  zone_id         = each.value.zone_id
  name            = each.value.name
  type            = try(each.value.type, "CNAME")
  content         = coalesce(try(each.value.content, null), cloudflare_zero_trust_tunnel_cloudflared.this.cname)
  ttl             = try(each.value.ttl, 1)
  proxied         = try(each.value.proxied, true)
  comment         = try(each.value.comment, null)
  priority        = try(each.value.priority, null)
  allow_overwrite = try(each.value.allow_overwrite, false)
  tags            = try(each.value.tags, null)
}

resource "cloudflare_zero_trust_access_application" "this" {
  for_each = var.access_applications

  account_id                   = var.account_id
  zone_id                      = try(each.value.zone_id, null)
  name                         = each.value.name
  domain                       = each.value.domain
  type                         = try(each.value.type, "self_hosted")
  allowed_idps                 = try(each.value.allowed_idps, null)
  auto_redirect_to_identity    = try(each.value.auto_redirect_to_identity, null)
  app_launcher_visible         = try(each.value.app_launcher_visible, null)
  allow_authenticate_via_warp  = try(each.value.allow_authenticate_via_warp, null)
  domain_type                  = try(each.value.domain_type, null)
  enable_binding_cookie        = try(each.value.enable_binding_cookie, null)
  http_only_cookie_attribute   = try(each.value.http_only_cookie_attribute, null)
  options_preflight_bypass     = try(each.value.options_preflight_bypass, null)
  same_site_cookie_attribute   = try(each.value.same_site_cookie_attribute, null)
  self_hosted_domains          = try(each.value.self_hosted_domains, null)
  service_auth_401_redirect    = try(each.value.service_auth_401_redirect, null)
  session_duration             = try(each.value.session_duration, null)
  skip_app_launcher_login_page = try(each.value.skip_app_launcher_login_page, null)
  skip_interstitial            = try(each.value.skip_interstitial, null)
  custom_deny_message          = try(each.value.custom_deny_message, null)
  custom_deny_url              = try(each.value.custom_deny_url, null)
  custom_non_identity_deny_url = try(each.value.custom_non_identity_deny_url, null)
  custom_pages                 = try(each.value.custom_pages, null)
  tags                         = try(each.value.tags, null)
}

resource "cloudflare_zero_trust_access_policy" "this" {
  for_each = var.access_policies

  account_id                     = var.account_id
  zone_id                        = try(each.value.zone_id, null)
  application_id                 = coalesce(try(each.value.application_id, null), try(cloudflare_zero_trust_access_application.this[each.value.application_key].id, null))
  name                           = each.value.name
  decision                       = try(each.value.decision, "allow")
  precedence                     = each.value.precedence
  approval_required              = try(each.value.approval_required, null)
  isolation_required             = try(each.value.isolation_required, null)
  purpose_justification_prompt   = try(each.value.purpose_justification_prompt, null)
  purpose_justification_required = try(each.value.purpose_justification_required, null)
  session_duration               = try(each.value.session_duration, null)

  dynamic "include" {
    for_each = each.value.include
    content {
      any_valid_service_token = try(include.value.any_valid_service_token, null)
      auth_method             = try(include.value.auth_method, null)
      certificate             = try(include.value.certificate, null)
      common_name             = try(include.value.common_name, null)
      common_names            = try(include.value.common_names, null)
      device_posture          = try(include.value.device_posture, null)
      email                   = try(include.value.email, null)
      email_domain            = try(include.value.email_domain, null)
      email_list              = try(include.value.email_list, null)
      everyone                = try(include.value.everyone, null)
      geo                     = try(include.value.geo, null)
      group                   = try(include.value.group, null)
      ip                      = try(include.value.ip, null)
      ip_list                 = try(include.value.ip_list, null)
      login_method            = try(include.value.login_method, null)
      service_token           = try(include.value.service_token, null)
    }
  }

  dynamic "exclude" {
    for_each = try(each.value.exclude, [])
    content {
      any_valid_service_token = try(exclude.value.any_valid_service_token, null)
      auth_method             = try(exclude.value.auth_method, null)
      certificate             = try(exclude.value.certificate, null)
      common_name             = try(exclude.value.common_name, null)
      common_names            = try(exclude.value.common_names, null)
      device_posture          = try(exclude.value.device_posture, null)
      email                   = try(exclude.value.email, null)
      email_domain            = try(exclude.value.email_domain, null)
      email_list              = try(exclude.value.email_list, null)
      everyone                = try(exclude.value.everyone, null)
      geo                     = try(exclude.value.geo, null)
      group                   = try(exclude.value.group, null)
      ip                      = try(exclude.value.ip, null)
      ip_list                 = try(exclude.value.ip_list, null)
      login_method            = try(exclude.value.login_method, null)
      service_token           = try(exclude.value.service_token, null)
    }
  }

  dynamic "require" {
    for_each = try(each.value.require, [])
    content {
      any_valid_service_token = try(require.value.any_valid_service_token, null)
      auth_method             = try(require.value.auth_method, null)
      certificate             = try(require.value.certificate, null)
      common_name             = try(require.value.common_name, null)
      common_names            = try(require.value.common_names, null)
      device_posture          = try(require.value.device_posture, null)
      email                   = try(require.value.email, null)
      email_domain            = try(require.value.email_domain, null)
      email_list              = try(require.value.email_list, null)
      everyone                = try(require.value.everyone, null)
      geo                     = try(require.value.geo, null)
      group                   = try(require.value.group, null)
      ip                      = try(require.value.ip, null)
      ip_list                 = try(require.value.ip_list, null)
      login_method            = try(require.value.login_method, null)
      service_token           = try(require.value.service_token, null)
    }
  }

  lifecycle {
    precondition {
      condition     = try(each.value.application_id, null) != null || try(each.value.application_key, null) != null
      error_message = "Each access policy must set either application_id or application_key."
    }
  }
}
