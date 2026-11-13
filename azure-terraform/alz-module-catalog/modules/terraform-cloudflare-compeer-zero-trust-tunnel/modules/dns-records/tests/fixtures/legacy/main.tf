# Test-only previous resource address, used to prove state-preserving moves.
terraform {
  required_providers {
    cloudflare = { source = "cloudflare/cloudflare", version = ">= 4.11, < 5.0" }
  }
}
variable "records" { type = map(any) }
resource "cloudflare_record" "record" {
  for_each        = var.records
  zone_id         = each.value.zone_id
  name            = each.value.name
  type            = each.value.type
  content         = each.value.content
  ttl             = 1
  proxied         = true
  allow_overwrite = false
}
output "record_ids" {
  value = { for key, record in cloudflare_record.record : key => record.id }
}
