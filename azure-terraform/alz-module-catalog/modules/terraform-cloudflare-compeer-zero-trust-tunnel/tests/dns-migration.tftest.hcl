mock_provider "cloudflare" {}

run "legacy_tunnel_dns_state" {
  command   = apply
  state_key = "tunnel_dns_migration"
  module {
    source = "./modules/dns-records/tests/fixtures/legacy"
  }
  variables {
    records = { pilot = {
      zone_id = "0123456789abcdef0123456789abcdef", name = "pilot.example.com", type = "CNAME", content = "example.cfargotunnel.com"
    } }
  }
}

run "tunnel_dns_move_preserves_existing_id_during_plan" {
  command   = plan
  state_key = "tunnel_dns_migration"
  variables {
    account_id    = "0123456789abcdef0123456789abcdef"
    name          = "pilot"
    tunnel_secret = "mock-secret-only"
    dns_records = { pilot = {
      zone_id = "0123456789abcdef0123456789abcdef", name = "pilot.example.com", content = "example.cfargotunnel.com"
    } }
  }
  assert {
    condition     = output.dns_record_ids["pilot"] == run.legacy_tunnel_dns_state.record_ids["pilot"]
    error_message = "The existing tunnel DNS ID must remain known and unchanged after the resource address move."
  }
}
