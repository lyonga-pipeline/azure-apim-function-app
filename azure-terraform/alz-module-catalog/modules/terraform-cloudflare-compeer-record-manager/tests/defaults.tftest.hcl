mock_provider "cloudflare" {}
variables {
  name    = "www"
  type    = "A"
  zone_id = "0123456789abcdef0123456789abcdef"
  value   = "203.0.113.10"
  ttl     = 300
}
run "create" {
  command = apply
  assert {
    condition     = cloudflare_record.record.name == "www"
    error_message = "record name not wired"
  }
  assert {
    condition     = cloudflare_record.record.value == "203.0.113.10"
    error_message = "A record value not wired"
  }
}
