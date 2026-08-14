resource "cloudflare_zone" "this" {
  for_each = var.enabled ? var.zones : {}

  zone       = each.value.zone
  account_id = each.value.account_id
  type       = try(each.value.type, "full")
  paused     = try(each.value.paused, false)
}

resource "cloudflare_record" "this" {
  for_each = var.enabled ? var.records : {}

  zone_id  = cloudflare_zone.this[each.value.zone_key].id
  name     = each.value.name
  value    = each.value.value
  type     = each.value.type
  ttl      = try(each.value.ttl, 1)
  proxied  = try(each.value.proxied, true)
  comment  = try(each.value.comment, null)
  priority = try(each.value.priority, null)
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
