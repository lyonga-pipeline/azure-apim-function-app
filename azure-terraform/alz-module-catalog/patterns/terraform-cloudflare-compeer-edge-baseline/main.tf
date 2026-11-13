# PHASE2 EXISTING: v5 4.4 NET-34: existing Cloudflare tunnel/Access/DNS configuration. Enable only after tenant ownership, API scopes and IdP approvals.
resource "cloudflare_zone" "zone" {
  for_each = var.enabled ? var.zones : {}

  zone       = each.value.zone
  account_id = each.value.account_id
  type       = try(each.value.type, "full")
  paused     = try(each.value.paused, false)
}

resource "cloudflare_record" "record" {
  for_each = var.enabled ? var.records : {}

  zone_id         = coalesce(try(each.value.zone_id, null), try(cloudflare_zone.zone[each.value.zone_key].id, null))
  name            = each.value.name
  content         = coalesce(try(each.value.content, null), try(each.value.value, null))
  type            = each.value.type
  ttl             = try(each.value.ttl, 1)
  proxied         = try(each.value.proxied, true)
  comment         = try(each.value.comment, null)
  priority        = try(each.value.priority, null)
  allow_overwrite = try(each.value.allow_overwrite, false)
  tags            = try(each.value.tags, null)
}

resource "cloudflare_ruleset" "ruleset" {
  for_each = var.enabled ? var.rulesets : {}

  zone_id     = try(coalesce(each.value.zone_id, try(cloudflare_zone.zone[each.value.zone_key].id, null)), null)
  account_id  = try(each.value.account_id, null)
  kind        = each.value.kind
  name        = each.value.name
  phase       = each.value.phase
  description = try(each.value.description, null)

  dynamic "rules" {
    for_each = try(each.value.rules, [])
    content {
      action      = try(rules.value.action, null)
      expression  = rules.value.expression
      description = try(rules.value.description, null)
      enabled     = try(rules.value.enabled, true)
      ref         = try(rules.value.ref, null)
      dynamic "action_parameters" {
        for_each = try(rules.value.action_parameters, null) == null ? [] : [rules.value.action_parameters]
        content {
          # PHASE 2: managed-WAF execute ID. Other action parameter schemas are
          # deliberately not silently accepted by this narrow adapter.
          id = action_parameters.value.id
        }
      }
    }
  }
}

locals {
  enabled_tunnels = var.enabled ? {
    for key, value in var.tunnels : key => value
    if coalesce(try(value.enabled, null), true)
  } : {}
}

resource "terraform_data" "tunnel_secret_contract" {
  count = length(local.enabled_tunnels) > 0 ? 1 : 0

  input = {
    tunnel_keys = sort(keys(local.enabled_tunnels))
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for key, value in local.enabled_tunnels : try(length(trimspace(var.tunnel_secrets[coalesce(try(value.tunnel_secret_key, null), key)])) > 0, false)
      ])
      error_message = "tunnel_secrets must contain a non-empty sensitive secret entry for each enabled tunnel key. This does not verify connector installation or runtime credentials."
    }
  }
}

module "zero_trust_tunnels" {
  source   = "../../modules/terraform-cloudflare-compeer-zero-trust-tunnel"
  for_each = local.enabled_tunnels

  account_id        = each.value.account_id
  name              = each.value.name
  tunnel_secret     = lookup(var.tunnel_secrets, coalesce(try(each.value.tunnel_secret_key, null), each.key), "")
  config_src        = try(each.value.config_src, "cloudflare")
  ingress_rules     = try(each.value.ingress_rules, [])
  catch_all_service = try(each.value.catch_all_service, "http_status:404")
  dns_records = {
    for record_key, record in try(each.value.dns_records, {}) : record_key => merge(record, {
      zone_id = coalesce(try(record.zone_id, null), try(cloudflare_zone.zone[record.zone_key].id, null))
    })
  }
  access_applications = try(each.value.access_applications, {})
  access_policies     = try(each.value.access_policies, {})
  access_team_name    = each.value.access_team_name

  depends_on = [terraform_data.tunnel_secret_contract, terraform_data.enterprise_contract]
}

# PHASE 2: new deployable roots enable these fail-closed publication controls.
resource "terraform_data" "enterprise_contract" {
  input = keys(local.enabled_tunnels)
  lifecycle {
    precondition {
      condition = !var.enforce_enterprise_controls || alltrue([for key, tunnel in local.enabled_tunnels :
        can(regex("^[A-Za-z0-9+/]{42}[AEIMQUYcgkosw048]=$", lookup(var.tunnel_secrets, coalesce(tunnel.tunnel_secret_key, key), "")))
      ])
      error_message = "Enterprise tunnels require canonical base64 encoding of a cryptographically generated 32-byte secret. Generate and supply it through the approved sensitive input process."
    }
    precondition {
      condition = !var.enforce_enterprise_controls || alltrue(flatten([
        for tunnel in values(local.enabled_tunnels) : [for rule in tunnel.ingress_rules : try(
          length(trimspace(rule.hostname)) > 0 && !strcontains(rule.hostname, "*") &&
          startswith(rule.service, "https://") && !try(coalesce(rule.origin_request.no_tls_verify, false), false) &&
          var.approved_public_applications[rule.hostname].classification == "external-apps" &&
          length(trimspace(var.approved_public_applications[rule.hostname].approval_reference)) > 0 &&
          (anytrue([for app_key, app in tunnel.access_applications :
            app.domain == rule.hostname && try(length(trimspace(tunnel.access_team_name)) > 0, false) && anytrue([for policy in values(tunnel.access_policies) :
              try(policy.application_key, null) == app_key && contains(["allow", "non_identity"], try(policy.decision, "allow"))
            ])
          ]) || try(length(trimspace(var.approved_public_applications[rule.hostname].external_authentication_reason)) > 0, false)), false)
        ]
      ]))
      error_message = "Publication requires an approved exact external-app hostname, HTTPS with TLS verification, and a declared Access allow/service policy or explicit alternative-authentication approval."
    }
    precondition {
      condition = !var.enforce_enterprise_controls || alltrue(flatten([for tunnel in values(local.enabled_tunnels) : concat(
        [tunnel.catch_all_service == "http_status:404"],
        [for record in values(tunnel.dns_records) : try(
          upper(try(record.type, "CNAME")) == "CNAME" && try(record.proxied, true) && try(record.content, null) == null &&
        anytrue([for rule in tunnel.ingress_rules : rule.hostname == record.name]), false)],
        [for policy in values(tunnel.access_policies) :
          try(policy.decision, "allow") != "bypass" && alltrue([for selector in policy.include :
            !try(coalesce(selector.everyone, false), false) &&
            !try(coalesce(selector.any_valid_service_token, false), false) &&
            anytrue([for field in ["group", "email", "service_token"] : try(length(selector[field]) > 0, false)])
        ])]
      )]))
      error_message = "Enterprise publication requires terminal 404, matching proxied tunnel CNAMEs, and narrowly scoped Access selectors without everyone/bypass/any-valid-token shortcuts."
    }
    precondition {
      condition     = !var.enforce_enterprise_controls || length(var.records) == 0
      error_message = "Use tunnel dns_records in enterprise mode. Generic top-level records bypass publication security ordering."
    }
    precondition {
      condition = alltrue(flatten([for ruleset in values(var.rulesets) : [for rule in ruleset.rules :
        try(rule.action_parameters, null) == null ? true : try(
        rule.action == "execute" && length(rule.action_parameters.id) == 32 && length(keys(rule.action_parameters)) == 1, false)
      ]]))
      error_message = "This adapter supports only action_parameters = { id = MANAGED_RULESET_ID } for execute rules; do not pass unsupported fields."
    }
  }
}
