resource "cloudflare_zone" "this" {
  for_each = var.enabled ? var.zones : {}

  zone       = each.value.zone
  account_id = each.value.account_id
  type       = try(each.value.type, "full")
  paused     = try(each.value.paused, false)
}

resource "cloudflare_record" "this" {
  for_each = var.enabled ? var.records : {}

  zone_id         = coalesce(try(each.value.zone_id, null), try(cloudflare_zone.this[each.value.zone_key].id, null))
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

resource "cloudflare_ruleset" "this" {
  for_each = var.enabled ? var.rulesets : {}

  zone_id     = try(each.value.zone_key, null) == null ? null : cloudflare_zone.this[each.value.zone_key].id
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
        for key, value in local.enabled_tunnels : contains(keys(var.tunnel_secrets), coalesce(try(value.tunnel_secret_key, null), key))
      ])
      error_message = "tunnel_secrets must contain a sensitive secret entry for each enabled tunnel key."
    }
  }
}

module "zero_trust_tunnels" {
  source   = "../../modules/terraform-cloudflare-compeer-zero-trust-tunnel"
  for_each = local.enabled_tunnels

  account_id        = each.value.account_id
  name              = each.value.name
  tunnel_secret     = var.tunnel_secrets[coalesce(try(each.value.tunnel_secret_key, null), each.key)]
  config_src        = try(each.value.config_src, "cloudflare")
  ingress_rules     = try(each.value.ingress_rules, [])
  catch_all_service = try(each.value.catch_all_service, "http_status:404")
  dns_records = {
    for record_key, record in try(each.value.dns_records, {}) : record_key => merge(record, {
      zone_id = coalesce(try(record.zone_id, null), try(cloudflare_zone.this[record.zone_key].id, null))
    })
  }
  access_applications = try(each.value.access_applications, {})
  access_policies     = try(each.value.access_policies, {})

  depends_on = [terraform_data.tunnel_secret_contract]
}
