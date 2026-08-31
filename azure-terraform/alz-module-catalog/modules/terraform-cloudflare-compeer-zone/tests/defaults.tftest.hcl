mock_provider "cloudflare" {}
variables {
  account_id = "0123456789abcdef0123456789abcdef"
  zone       = "example.com"
}
run "create" {
  command = apply
  assert {
    condition     = cloudflare_zone.zone.zone == "example.com"
    error_message = "zone not wired"
  }
  assert {
    condition     = length(cloudflare_zone_settings_override.zone_settings) == 0
    error_message = "settings override should be off by default"
  }
}
