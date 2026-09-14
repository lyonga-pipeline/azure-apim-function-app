# Resource-address history for the "this" -> semantic-name cleanup.
# Keeps a plan against already-applied state a pure state move (no
# destroy/recreate) instead of replacing every renamed resource.
# Safe to delete once every real workspace has applied past this change.

moved {
  from = cloudflare_zone.this
  to   = cloudflare_zone.zone
}

moved {
  from = cloudflare_record.this
  to   = cloudflare_record.record
}

moved {
  from = cloudflare_ruleset.this
  to   = cloudflare_ruleset.ruleset
}
