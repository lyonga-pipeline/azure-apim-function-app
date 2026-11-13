# Shared by the edge pattern and tunnel helper; each DNS record has one caller.
resource "cloudflare_record" "record" {
  for_each = var.records

  zone_id         = each.value.zone_id
  name            = each.value.name
  type            = each.value.type
  content         = each.value.content
  ttl             = each.value.ttl
  proxied         = each.value.proxied
  comment         = each.value.comment
  priority        = each.value.priority
  allow_overwrite = each.value.allow_overwrite
  tags            = each.value.tags
}
