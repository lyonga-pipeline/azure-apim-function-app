mock_provider "cloudflare" {}
run "empty_records_create_nothing" {
  command = plan
  assert {
    condition     = length(cloudflare_record.record) == 0
    error_message = "Empty DNS input must not create records."
  }
}
run "record_defaults_and_content_are_preserved" {
  command = plan
  variables {
    records = { pilot = {
      zone_id = "0123456789abcdef0123456789abcdef"
      name    = "pilot.example.com"
      type    = "CNAME"
      content = "00000000-0000-4000-8000-000000000001.cfargotunnel.com"
    } }
  }
  assert {
    condition = (cloudflare_record.record["pilot"].proxied && cloudflare_record.record["pilot"].ttl == 1 &&
    !cloudflare_record.record["pilot"].allow_overwrite && endswith(cloudflare_record.record["pilot"].content, ".cfargotunnel.com"))
    error_message = "Shared DNS must preserve proxied tunnel content, automatic TTL and safe overwrite defaults."
  }
}
run "generic_record_overrides_are_preserved" {
  command = plan
  variables {
    records = { verification = {
      zone_id = "0123456789abcdef0123456789abcdef"
      name    = "_verify.example.com"
      type    = "TXT"
      content = "public-domain-verification-value"
      ttl     = 300
      proxied = false
      comment = "Approved verification record"
    } }
  }
  assert {
    condition = (cloudflare_record.record["verification"].type == "TXT" && !cloudflare_record.record["verification"].proxied &&
    cloudflare_record.record["verification"].ttl == 300 && cloudflare_record.record["verification"].comment == "Approved verification record")
    error_message = "Shared DNS must not turn generic records into tunnel CNAMEs."
  }
}
run "multi_value_txt_records_are_supported" {
  command = plan
  variables {
    records = {
      first  = { zone_id = "0123456789abcdef0123456789abcdef", name = "verify.example.com", type = "TXT", content = "verification-one", proxied = false }
      second = { zone_id = "0123456789abcdef0123456789abcdef", name = "verify.example.com", type = "TXT", content = "verification-two", proxied = false }
    }
  }
  assert {
    condition     = length(cloudflare_record.record) == 2
    error_message = "DNS de-duplication must not reject legitimate multi-value TXT records."
  }
}
run "cname_cannot_share_a_hostname" {
  command = plan
  variables {
    records = {
      tunnel = { zone_id = "0123456789abcdef0123456789abcdef", name = "pilot.example.com", type = "CNAME", content = "example.cfargotunnel.com" }
      legacy = { zone_id = "0123456789abcdef0123456789abcdef", name = "PILOT.EXAMPLE.COM.", type = "A", content = "192.0.2.1" }
    }
  }
  expect_failures = [var.records]
}
