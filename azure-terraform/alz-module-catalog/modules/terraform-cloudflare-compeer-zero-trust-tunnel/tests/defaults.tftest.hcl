mock_provider "cloudflare" {}
variables {
  account_id    = "0123456789abcdef0123456789abcdef"
  name          = "platform-tunnel"
  tunnel_secret = "dGVzdC10dW5uZWwtc2VjcmV0LWJhc2U2NA=="
}
run "create" {
  command = apply
  assert {
    condition     = cloudflare_zero_trust_tunnel_cloudflared.this.name == "platform-tunnel"
    error_message = "tunnel name not wired"
  }
}
run "no_access_resources_by_default" {
  command = plan
  assert {
    condition     = length(cloudflare_zero_trust_access_application.this) == 0 && length(cloudflare_zero_trust_access_policy.this) == 0
    error_message = "access resources should be empty by default"
  }
}
