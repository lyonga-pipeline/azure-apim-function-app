#############################
## Cloudflare Record Manager
############################
resource "cloudflare_record" "record" {
  name    = var.name
  type    = var.type
  zone_id = var.zone_id

  allow_overwrite = var.allow_overwrite
  comment         = var.comment
  priority        = var.priority
  proxied         = var.proxied
  tags            = var.tags
  ttl             = var.ttl
  value           = local.require_value ? var.value : null

  dynamic "data" {
    for_each = local.require_data && length(var.data) > 0 ? var.data : {}
    content {
      algorithm      = lookup(data.value, "algorithm", null)
      altitude       = lookup(data.value, "altitude", null)
      certificate    = lookup(data.value, "certificate", null)
      content        = lookup(data.value, "content", null)
      digest         = lookup(data.value, "digest", null)
      fingerprint    = lookup(data.value, "fingerprint", null)
      flags          = lookup(data.value, "flags", null)
      key_tag        = lookup(data.value, "key_tag", null)
      lat_degrees    = lookup(data.value, "lat_degrees", null)
      lat_direction  = lookup(data.value, "lat_direction", null)
      lat_minutes    = lookup(data.value, "lat_minutes", null)
      lat_seconds    = lookup(data.value, "lat_seconds", null)
      long_degrees   = lookup(data.value, "long_degrees", null)
      long_direction = lookup(data.value, "long_direction", null)
      long_minutes   = lookup(data.value, "long_minutes", null)
      long_seconds   = lookup(data.value, "long_seconds", null)
      matching_type  = lookup(data.value, "matching_type", null)
      name           = lookup(data.value, "name", null)
      order          = lookup(data.value, "order", null)
      port           = lookup(data.value, "port", null)
      precision_horz = lookup(data.value, "precision_horz", null)
      precision_vert = lookup(data.value, "precision_vert", null)
      preference     = lookup(data.value, "preference", null)
      priority       = lookup(data.value, "priority", null)
      proto          = lookup(data.value, "proto", null) # Corrected typo here
      protocol       = lookup(data.value, "protocol", null)
      public_key     = lookup(data.value, "public_key", null)
      regex          = lookup(data.value, "regex", null)
      replacement    = lookup(data.value, "replacement", null)
      selector       = lookup(data.value, "selector", null)
      service        = lookup(data.value, "service", null)
      size           = lookup(data.value, "size", null)
      tag            = lookup(data.value, "tag", null)
      usage          = lookup(data.value, "usage", null)
      value          = lookup(data.value, "value", null)
      weight         = lookup(data.value, "weight", null)
    }
  }

  dynamic "timeouts" {
    for_each = length(var.timeouts) > 0 ? var.timeouts : {}
    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
    }
  }
}
