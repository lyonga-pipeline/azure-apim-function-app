# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = cloudflare_zero_trust_tunnel_cloudflared.this
  to   = cloudflare_zero_trust_tunnel_cloudflared.tunnel
}

moved {
  from = cloudflare_zero_trust_tunnel_cloudflared_config.this
  to   = cloudflare_zero_trust_tunnel_cloudflared_config.tunnel_config
}

moved {
  from = cloudflare_record.this
  to   = cloudflare_record.record
}

moved {
  from = cloudflare_zero_trust_access_application.this
  to   = cloudflare_zero_trust_access_application.access_application
}

moved {
  from = cloudflare_zero_trust_access_policy.this
  to   = cloudflare_zero_trust_access_policy.access_policy
}
