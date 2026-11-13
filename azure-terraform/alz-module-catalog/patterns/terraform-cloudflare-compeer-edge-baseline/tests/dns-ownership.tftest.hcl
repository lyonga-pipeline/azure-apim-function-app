mock_provider "cloudflare" {}

run "generic_records_use_the_shared_implementation" {
  command = apply
  variables {
    enabled = true
    records = {
      pilot = {
        zone_id = "0123456789abcdef0123456789abcdef"
        name    = "pilot.example.com"
        type    = "CNAME"
        value   = "example.cfargotunnel.com" # Preserve the legacy value alias.
      }
    }
  }
  assert {
    condition     = output.record_ids == module.dns_records.ids && contains(keys(output.record_ids), "pilot")
    error_message = "Generic DNS output keys and the legacy value alias must be preserved."
  }
}

run "overlapping_generic_and_tunnel_records_are_rejected" {
  command = plan
  variables {
    enabled = true
    records = {
      duplicate = {
        zone_id = "0123456789abcdef0123456789abcdef"
        name    = "PILOT.EXAMPLE.COM."
        type    = "CNAME"
        content = "example.cfargotunnel.com"
      }
    }
    tunnels = {
      pilot = {
        account_id  = "0123456789abcdef0123456789abcdef"
        name        = "pilot"
        dns_records = { app = { zone_id = "0123456789abcdef0123456789abcdef", name = "pilot.example.com" } }
      }
    }
    tunnel_secrets = { pilot = "mock-secret-only" }
  }
  expect_failures = [terraform_data.enterprise_contract]
}

run "legacy_edge_dns_state" {
  command   = apply
  state_key = "edge_dns_migration"
  module {
    source = "../../modules/terraform-cloudflare-compeer-zero-trust-tunnel/modules/dns-records/tests/fixtures/legacy"
  }
  variables {
    records = { pilot = {
      zone_id = "0123456789abcdef0123456789abcdef", name = "pilot.example.com", type = "CNAME", content = "example.cfargotunnel.com"
    } }
  }
}

run "edge_dns_move_preserves_existing_id_during_plan" {
  command   = plan
  state_key = "edge_dns_migration"
  variables {
    enabled = true
    records = { pilot = {
      zone_id = "0123456789abcdef0123456789abcdef", name = "pilot.example.com", type = "CNAME", content = "example.cfargotunnel.com"
    } }
  }
  assert {
    condition     = output.record_ids["pilot"] == run.legacy_edge_dns_state.record_ids["pilot"]
    error_message = "The existing DNS ID must remain known and unchanged after the resource address move."
  }
}
