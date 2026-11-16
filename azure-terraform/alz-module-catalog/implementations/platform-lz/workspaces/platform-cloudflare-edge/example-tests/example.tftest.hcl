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
    condition     = length(output.zone_ids) == length(var.cloudflare_edge.zones) && length(output.ruleset_ids) == 2 && length(output.record_ids) == 0
    error_message = "Respect zone ownership, use custom/managed WAF phases and no generic DNS bypass."
  }
  assert {
    condition = alltrue([for tier in ["external_nonprod", "external_prod"] :
      toset(keys(output.access_application_ids[tier])) == toset(keys(var.cloudflare_edge.tunnels[tier].access_applications)) &&
      toset(keys(output.access_policy_ids[tier])) == toset(keys(var.cloudflare_edge.tunnels[tier].access_policies)) &&
      toset(keys(output.tunnel_dns_record_ids[tier])) == toset(keys(var.cloudflare_edge.tunnels[tier].dns_records))
    ])
    error_message = "Both tier hostnames must have Access application/policy and tunnel DNS ownership."
  }
  assert {
    condition = alltrue([for tunnel in values(var.cloudflare_edge.tunnels) :
      toset([for app in values(tunnel.access_applications) : app.domain]) ==
      toset([for rule in tunnel.ingress_rules : rule.hostname]) &&
      toset([for record in values(tunnel.dns_records) : record.name]) ==
      toset([for rule in tunnel.ingress_rules : rule.hostname]) &&
      alltrue([for rule in tunnel.ingress_rules :
        contains(keys(var.cloudflare_edge.approved_public_applications), rule.hostname) &&
        alltrue([for ruleset in values(var.cloudflare_edge.rulesets) :
          anytrue([for waf in ruleset.rules : strcontains(waf.expression, "\"${rule.hostname}\"")])
        ])
      ])
    ])
    error_message = "Every example hostname must match approval, ingress, Access, DNS and both WAF phases."
  }
}
