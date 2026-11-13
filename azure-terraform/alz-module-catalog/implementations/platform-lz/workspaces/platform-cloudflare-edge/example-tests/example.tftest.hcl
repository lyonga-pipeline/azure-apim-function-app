# Run with -test-directory=example-tests and a sanitized -var-file copy.
# Uses mock Cloudflare only; never publishes DNS or contacts the live account.
mock_provider "cloudflare" {}

run "two_tiers_and_security_configuration" {
  command = plan
  assert {
    condition     = toset(keys(output.tunnel_ids)) == toset(["external_nonprod", "external_prod"])
    error_message = "Example must create exactly one shared nonprod tunnel and one prod tunnel."
  }
  assert {
    condition     = length(output.zone_ids) == 1 && length(output.ruleset_ids) == 2 && length(output.record_ids) == 0
    error_message = "Use one approved zone, custom/managed WAF phases and no generic DNS bypass."
  }
  assert {
    condition = alltrue([for tier in ["external_nonprod", "external_prod"] :
      length(output.access_application_ids[tier]) == 1 &&
      length(output.access_policy_ids[tier]) == 1 &&
      length(output.tunnel_dns_record_ids[tier]) == 1
    ])
    error_message = "Both tier hostnames must have Access application/policy and tunnel DNS ownership."
  }
}
