mock_provider "cloudflare" {}
variables {
  ruleset_kind  = "zone"
  ruleset_name  = "default-waf"
  ruleset_phase = "http_request_firewall_custom"
  description   = "Baseline custom firewall rules."
  zone_id       = "abcdef0123456789abcdef0123456789"
  rules = [
    {
      expression        = "(http.host eq \"admin.example.com\")"
      action            = "block"
      description       = "block admin host"
      action_parameters = null
    }
  ]
}
run "create" {
  command = apply
  assert {
    condition     = cloudflare_ruleset.ruleset.name == "default-waf"
    error_message = "ruleset name not wired"
  }
  assert {
    condition     = cloudflare_ruleset.ruleset.phase == "http_request_firewall_custom"
    error_message = "phase not wired"
  }
}
run "rejects_both_scopes" {
  command = plan
  variables {
    cloudflare_account_id = "0123456789abcdef0123456789abcdef"
  }
  expect_failures = [cloudflare_ruleset.ruleset]
}
